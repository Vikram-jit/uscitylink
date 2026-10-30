// One WebRTC audio connection to the other person on a call.
//
// Signalling rules (same in the Flutter app, lib/services/call/webrtc_engine.dart):
//   - only the CALLER sends offers (first offer after "call:accepted", and ICE restarts);
//     the callee only answers, or asks for a restart with { type: "restart-request" } — so the two
//     sides never offer at the same time;
//   - ICE candidates that arrive before the remote description are queued.
// The class knows nothing about Socket.IO; `sendSignal` carries messages through call:signal.
// For group calls / recording this is the piece to swap for an SFU client.

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
  onRemoteStream: (stream: MediaStream) => void;
  onState: (state: EngineState) => void;
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

export async function getMicrophone(deviceId?: string): Promise<MediaStream> {
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

  constructor(private opts: EngineOptions) {
    this.pc = new RTCPeerConnection({ iceServers: opts.iceServers, bundlePolicy: 'max-bundle' });
    opts.localStream.getTracks().forEach((t) => this.pc.addTrack(t, opts.localStream));

    this.pc.onicecandidate = (e) => {
      if (e.candidate) opts.sendSignal({ type: 'candidate', candidate: e.candidate.toJSON() });
    };
    this.pc.ontrack = (e) => {
      const stream = e.streams[0] || new MediaStream([e.track]);
      opts.onRemoteStream(stream);
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
    this.opts.localStream.getTracks().forEach((t) => t.stop());
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
