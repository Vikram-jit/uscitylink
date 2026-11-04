// One WebRTC connection (voice, plus video when a camera is on) to another person on a call.
//
// Signalling rules (same in the Flutter app, lib/services/call/webrtc_engine.dart):
//   - only the CALLER sends offers (first offer after "call:accepted", and ICE restarts);
//     the callee only answers, or asks for a restart with { type: "restart-request" } — so the two
//     sides never offer at the same time;
//   - ICE candidates that arrive before the remote description are queued.
// The class knows nothing about Socket.IO; `sendSignal` carries messages through call:signal.
//
// Video without renegotiation: every connection carries a video slot from the start (the caller adds
// it to its offer; the callee switches the offered slot to send+receive before answering). Turning a
// camera on or off only swaps the track in that slot (setCamera), so no new offer/answer is needed.
// An older app that offers audio only simply has no video slot: audio works, video is skipped.

export type EngineState = 'connecting' | 'connected' | 'reconnecting' | 'failed' | 'closed';

export type SignalData =
  | { type: 'offer' | 'answer'; sdp: string; restart?: boolean }
  | { type: 'candidate'; candidate: RTCIceCandidateInit }
  | { type: 'restart-request' };

export interface EngineOptions {
  iceServers: RTCIceServer[];
  isCaller: boolean;
  localStream: MediaStream;
  sendSignal: (data: SignalData) => void;
  /** The other person's audio + video (one stream; it gains a video track when theirs arrives). */
  onRemoteStream: (stream: MediaStream) => void;
  onState: (state: EngineState) => void;
  /**
   * Group calls share one microphone between the connections to each person: closing one of them
   * must not stop it. Default true (a 1-to-1 engine owns its microphone).
   */
  stopTracksOnClose?: boolean;
}

export interface CallStatsSummary {
  rttMs?: number;
  jitterMs?: number;
  packetLossPct?: number;
  bytesSent?: number;
  bytesReceived?: number;
  relay?: boolean;
  codec?: string;
  localCandidate?: string;
  remoteCandidate?: string;
  iceRestarts: number;
  platform: string;
}

const MAX_RESTARTS = 6;

/** Why the microphone could not be opened, in words a dispatcher can act on. */
export function microphoneErrorText(err: unknown, action: string): string {
  if (typeof window !== 'undefined' && (!window.isSecureContext || !navigator.mediaDevices)) {
    return `Calls need a secure page: open this site with https:// (the browser blocks the microphone on http://) to ${action}`;
  }
  const name = (err as { name?: string })?.name;
  if (name === 'NotAllowedError' || name === 'SecurityError') {
    return `Microphone is blocked. Click the lock icon next to the address, set Microphone to Allow, reload the page, then try again to ${action}`;
  }
  if (name === 'NotFoundError' || name === 'OverconstrainedError') {
    return `No microphone found. Plug one in or choose another in the call settings to ${action}`;
  }
  if (name === 'NotReadableError') {
    return `The microphone is in use by another app. Close it and try again to ${action}`;
  }
  return `Could not open the microphone to ${action}`;
}

/** The camera for video calls (640×360, 15 fps — enough for faces, light on drivers' data). */
export async function getCamera(deviceId?: string): Promise<MediaStreamTrack> {
  if (!navigator.mediaDevices?.getUserMedia) throw new DOMException('Insecure context', 'SecurityError');
  const stream = await navigator.mediaDevices.getUserMedia({
    video: {
      deviceId: deviceId ? { exact: deviceId } : undefined,
      width: { ideal: 640 },
      height: { ideal: 360 },
      frameRate: { ideal: 15, max: 24 },
    },
    audio: false,
  });
  return stream.getVideoTracks()[0];
}

export async function getMicrophone(deviceId?: string): Promise<MediaStream> {
  if (!navigator.mediaDevices?.getUserMedia) throw new DOMException('Insecure context', 'SecurityError');
  return navigator.mediaDevices.getUserMedia({
    audio: {
      deviceId: deviceId ? { exact: deviceId } : undefined,
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
    },
    video: false,
  });
}

export class WebRtcEngine {
  private pc: RTCPeerConnection;
  private pending: RTCIceCandidateInit[] = [];
  private restarts = 0;
  private restartTimer: ReturnType<typeof setTimeout> | null = null;
  private closed = false;
  private state: EngineState = 'connecting';
  private camera: MediaStreamTrack | null = null;
  private videoLimit: { maxBitrate: number; maxFramerate: number; scale: number } | null = null;
  private remote = new MediaStream();

  constructor(private opts: EngineOptions) {
    this.pc = new RTCPeerConnection({ iceServers: opts.iceServers, bundlePolicy: 'max-bundle' });
    opts.localStream.getAudioTracks().forEach((t) => this.pc.addTrack(t, opts.localStream));
    // The caller's offer carries the video slot (the callee gets it from the offer)
    if (opts.isCaller) this.pc.addTransceiver('video', { direction: 'sendrecv' });

    this.pc.onicecandidate = (e) => {
      if (e.candidate) opts.sendSignal({ type: 'candidate', candidate: e.candidate.toJSON() });
    };
    this.pc.ontrack = (e) => {
      // Audio and video arrive separately: keep them together in one stream for the UI. A NEW stream
      // each time: a <video> already showing a stream doesn't start rendering a track added to it later.
      const keep = this.remote.getTracks().filter((t) => t.kind !== e.track.kind);
      this.remote = new MediaStream([...keep, e.track]);
      opts.onRemoteStream(this.remote);
    };
    this.pc.onconnectionstatechange = () => this.onConnectionState();
  }

  /** Caller: send the first offer once the other side accepted. Callee: wait for it. */
  async start() {
    if (this.opts.isCaller) await this.offer(false);
  }

  async handleSignal(data: SignalData) {
    if (this.closed) return;
    try {
      if (data.type === 'offer') {
        await this.pc.setRemoteDescription({ type: 'offer', sdp: data.sdp });
        // Callee: send video back in the slot the caller offered (and attach a camera already on)
        const video = this.videoTransceiver();
        if (video && video.direction !== 'sendrecv' && video.currentDirection !== 'stopped') video.direction = 'sendrecv';
        await this.applyCamera();
        await this.flushCandidates();
        const answer = await this.pc.createAnswer();
        await this.pc.setLocalDescription(answer);
        this.opts.sendSignal({ type: 'answer', sdp: answer.sdp || '' });
      } else if (data.type === 'answer') {
        if (this.pc.signalingState !== 'have-local-offer') return;
        await this.pc.setRemoteDescription({ type: 'answer', sdp: data.sdp });
        await this.flushCandidates();
      } else if (data.type === 'candidate') {
        if (this.pc.remoteDescription) await this.pc.addIceCandidate(data.candidate);
        else this.pending.push(data.candidate);
      } else if (data.type === 'restart-request' && this.opts.isCaller) {
        this.restartIce();
      }
    } catch (err) {
      console.warn('[call] signal failed', data.type, err);
    }
  }

  setMuted(muted: boolean) {
    this.opts.localStream.getAudioTracks().forEach((t) => (t.enabled = !muted));
  }

  private videoTransceiver(): RTCRtpTransceiver | undefined {
    return this.pc.getTransceivers().find((t) => t.receiver.track?.kind === 'video' && t.currentDirection !== 'stopped');
  }

  /** Camera on (a track) or off (null). No renegotiation: the video slot just changes track. */
  async setCamera(track: MediaStreamTrack | null) {
    this.camera = track;
    await this.applyCamera();
  }

  /** Lower the video's quality in big group calls (everyone sends to everyone). */
  async setVideoLimit(limit: { maxBitrate: number; maxFramerate: number; scale: number }) {
    this.videoLimit = limit;
    await this.applyCamera();
  }

  private async applyCamera() {
    const sender = this.videoTransceiver()?.sender;
    if (!sender || this.closed) return;
    try {
      if (sender.track !== this.camera) await sender.replaceTrack(this.camera);
      if (this.camera && this.videoLimit) {
        const params = sender.getParameters();
        if (!params.encodings?.length) params.encodings = [{}];
        params.encodings[0].maxBitrate = this.videoLimit.maxBitrate;
        params.encodings[0].maxFramerate = this.videoLimit.maxFramerate;
        params.encodings[0].scaleResolutionDownBy = this.videoLimit.scale;
        await sender.setParameters(params);
      }
    } catch (err) {
      console.warn('[call] camera update failed', err);
    }
  }

  /** Send a different microphone track (group calls switch it on every connection at once). */
  async replaceTrack(track: MediaStreamTrack) {
    const sender = this.pc.getTransceivers().find((t) => t.receiver.track?.kind === 'audio')?.sender;
    await sender?.replaceTrack(track);
  }

  /** Swap the microphone mid-call without renegotiating. */
  async switchMicrophone(deviceId: string, muted: boolean) {
    const stream = await getMicrophone(deviceId);
    const track = stream.getAudioTracks()[0];
    track.enabled = !muted;
    const sender = this.pc.getSenders().find((s) => s.track?.kind === 'audio');
    await sender?.replaceTrack(track);
    this.opts.localStream.getAudioTracks().forEach((t) => {
      t.stop();
      this.opts.localStream.removeTrack(t);
    });
    this.opts.localStream.addTrack(track);
  }

  /** Network changed (Wi-Fi ↔ 4G) or the other side reconnected: find a new path. */
  restartIce() {
    if (this.closed) return;
    if (this.restarts >= MAX_RESTARTS) return this.setState('failed');
    this.restarts += 1;
    this.setState('reconnecting');
    if (this.opts.isCaller) void this.offer(true);
    else this.opts.sendSignal({ type: 'restart-request' });
  }

  async stats(): Promise<CallStatsSummary> {
    const out: CallStatsSummary = { iceRestarts: this.restarts, platform: 'web' };
    try {
      const report = await this.pc.getStats();
      const byId = new Map<string, any>();
      report.forEach((r: any) => byId.set(r.id, r));
      report.forEach((r: any) => {
        if (r.type === 'candidate-pair' && (r.selected || r.nominated) && r.state === 'succeeded') {
          out.rttMs = r.currentRoundTripTime !== undefined ? Math.round(r.currentRoundTripTime * 1000) : out.rttMs;
          out.bytesSent = r.bytesSent;
          out.bytesReceived = r.bytesReceived;
          const local = byId.get(r.localCandidateId);
          const remote = byId.get(r.remoteCandidateId);
          out.localCandidate = local?.candidateType;
          out.remoteCandidate = remote?.candidateType;
          out.relay = local?.candidateType === 'relay' || remote?.candidateType === 'relay';
        }
        if (r.type === 'inbound-rtp' && r.kind === 'audio') {
          out.jitterMs = r.jitter !== undefined ? Math.round(r.jitter * 1000) : undefined;
          const lost = r.packetsLost || 0;
          const got = r.packetsReceived || 0;
          out.packetLossPct = got + lost ? Math.round((lost / (got + lost)) * 1000) / 10 : 0;
          const codec = r.codecId ? byId.get(r.codecId) : null;
          out.codec = codec?.mimeType;
        }
      });
    } catch {
      // stats are best-effort
    }
    return out;
  }

  close() {
    if (this.closed) return;
    this.closed = true;
    if (this.restartTimer) clearTimeout(this.restartTimer);
    this.pc.onicecandidate = null;
    this.pc.ontrack = null;
    this.pc.onconnectionstatechange = null;
    this.pc.close();
    if (this.opts.stopTracksOnClose !== false) this.opts.localStream.getTracks().forEach((t) => t.stop());
    this.setState('closed');
  }

  // ---------- internals ----------

  private async offer(iceRestart: boolean) {
    try {
      const offer = await this.pc.createOffer({ iceRestart });
      await this.pc.setLocalDescription(offer);
      this.opts.sendSignal({ type: 'offer', sdp: offer.sdp || '', restart: iceRestart || undefined });
    } catch (err) {
      console.warn('[call] offer failed', err);
    }
  }

  private async flushCandidates() {
    const queued = this.pending.splice(0);
    for (const c of queued) {
      try {
        await this.pc.addIceCandidate(c);
      } catch {
        // stale candidate after a restart
      }
    }
  }

  private onConnectionState() {
    const s = this.pc.connectionState;
    if (s === 'connected') {
      if (this.restartTimer) clearTimeout(this.restartTimer);
      this.restartTimer = null;
      this.setState('connected');
    } else if (s === 'disconnected') {
      // Often recovers by itself within a couple of seconds; restart if it doesn't
      this.setState('reconnecting');
      if (this.restartTimer) clearTimeout(this.restartTimer);
      this.restartTimer = setTimeout(() => this.restartIce(), 2500);
    } else if (s === 'failed') {
      this.restartIce();
    }
  }

  private setState(state: EngineState) {
    if (this.state === state) return;
    this.state = state;
    this.opts.onState(state);
  }
}

/**
 * Recorded calls: sends this side's microphone to the server, which records both voices (see
 * server/src/calls/callRecorder.ts). A separate send-only connection, so it can never disturb the
 * call's own audio. Uses the call's microphone track, so muting is respected.
 */
export class RecordingUplink {
  private pc: RTCPeerConnection | null = null;
  private closed = false;
  private retries = 0;

  constructor(
    private opts: {
      iceServers: RTCIceServer[];
      track: MediaStreamTrack;
      /** "Record video" is on for this call: also send the camera (when it's on). */
      video?: boolean;
      /** Sends the offer to the server (call:rec_offer) and returns its answer. */
      offer: (sdp: string) => Promise<string | null>;
    }
  ) {}

  async start(): Promise<boolean> {
    if (this.closed) return false;
    const pc = new RTCPeerConnection({ iceServers: this.opts.iceServers });
    this.pc = pc;
    pc.addTransceiver(this.opts.track, { direction: 'sendonly' });
    if (this.opts.video) pc.addTransceiver(this.camera || 'video', { direction: 'sendonly' });
    try {
      await pc.setLocalDescription(await pc.createOffer());
      // One round trip: send the offer with the candidates found within a second (local + STUN)
      // instead of trickling them; waiting for every TURN candidate delayed the start of recording
      await new Promise<void>((resolve) => {
        if (pc.iceGatheringState === 'complete') return resolve();
        const done = () => pc.iceGatheringState === 'complete' && resolve();
        pc.addEventListener('icegatheringstatechange', done);
        setTimeout(resolve, 1000);
      });
      const answer = await this.opts.offer(pc.localDescription?.sdp || '');
      if (!answer || this.closed) return false;
      await pc.setRemoteDescription({ type: 'answer', sdp: answer });
      pc.onconnectionstatechange = () => {
        if (pc.connectionState === 'failed' && !this.closed && this.retries < 3) {
          this.retries += 1;
          pc.close();
          setTimeout(() => void this.start(), 1000 * this.retries);
        }
      };
      return true;
    } catch (err) {
      console.warn('[call] recording uplink failed', err);
      return false;
    }
  }

  private camera: MediaStreamTrack | null = null;

  /** Camera on/off, for calls that keep video in the recording. */
  async setCamera(track: MediaStreamTrack | null) {
    this.camera = track;
    const sender = this.pc?.getTransceivers().find((t) => t.receiver.track?.kind === 'video')?.sender;
    await sender?.replaceTrack(track).catch(() => undefined);
  }

  /** The microphone was switched mid-call. */
  async replaceTrack(track: MediaStreamTrack) {
    this.opts.track = track;
    const sender = this.pc?.getTransceivers().find((t) => t.receiver.track?.kind === 'audio')?.sender;
    await sender?.replaceTrack(track).catch(() => undefined);
  }

  close() {
    this.closed = true;
    if (this.pc) {
      this.pc.onconnectionstatechange = null;
      this.pc.close();
    }
    this.pc = null;
  }
}
