'use client';

import * as React from 'react';
import { toast } from 'react-toastify';

import { useSocket } from '@/lib/socketProvider';
import { useSocketEvent } from '@/hooks/use-socket-event';
import { useSaveCallQualityMutation } from '@/redux/CallApiSlice';

import { playEndTone, playRecordingTone, playRingback, playRingtone, stopTones } from './sounds';
import { getCamera, getMicrophone, microphoneErrorText, RecordingUplink, SignalData, WebRtcEngine } from './webrtcEngine';

// Voice calls on the web dashboard. One call at a time; the server (server/src/calls) decides who
// rings and when a call ends, this provider runs the WebRTC side and the UI state.
//
//   idle ─startCall→ outgoing ─call:accepted→ connecting ─media up→ active ─call:ended→ ended → idle
//   idle ─call:incoming→ incoming ─accept→ connecting → active …
//
// Group calls (staff adds staff): one WebRTC connection per other person, all sharing this tab's
// microphone. Whoever joins sends the offers to everyone already on the call; signals carry `to`
// and come back with `from`. A 1-to-1 call is the same thing with one connection.
//
// Video: any call can turn its camera on/off (webrtcEngine.setCamera — no renegotiation); camera
// state travels with call:media { video }. A "video call" just starts with the camera on.

export type CallPhase = 'idle' | 'outgoing' | 'incoming' | 'connecting' | 'active' | 'ended';

export interface CallPeer {
  id: string;
  name: string;
  role: 'staff' | 'driver';
}

export interface CallState {
  phase: CallPhase;
  callId: string | null;
  peer: CallPeer | null;
  channelName: string;
  direction: 'in' | 'out' | null;
  answeredAt: number | null;
  muted: boolean;
  remoteMuted: boolean;
  reconnecting: boolean;
  endedText: string | null;
  /** Other drivers ringing this dispatcher at the same time (shown one after another). */
  moreIncoming: number;
  /** The call is recorded (both people are told: tone + "Recorded" badge). */
  recording: boolean;
  /** Everyone on the call except me (1 person on a normal call, more on a group call). */
  members: CallPeer[];
  /** People asked to join who haven't answered yet. */
  pending: CallPeer[];
  /** People on the call who muted themselves. */
  mutedIds: string[];
  maxParticipants: number;
  /** Incoming request to join someone else's call: who asked. */
  invitedBy: CallPeer | null;
  /** That request is a transfer: whoever asked hands the call over and leaves. */
  transfer: boolean;
  /** Started as a video call (the caller's camera on). Any call can turn cameras on/off. */
  callType: 'audio' | 'video';
  /** My camera is on. */
  cameraOn: boolean;
  /** People on the call whose camera is on. */
  remoteCamera: string[];
  /** People whose app can show video (older driver apps are audio-only). */
  videoCapable: string[];
  /** The recording keeps video too (admin "Record video"). */
  recordVideo: boolean;
}

/** An answered call somewhere in the company: which driver, and who is on it (chat "On call" marks). */
export interface OnCallInfo {
  callId: string;
  driverId: string;
  channelId: string;
  members: CallPeer[];
  answeredAt: number | null;
}

interface CallContextValue extends CallState {
  startCall: (driver: { id: string; name: string }, opts?: { video?: boolean }) => Promise<void>;
  accept: (opts?: { video?: boolean }) => Promise<void>;
  /** Camera on/off during the call. */
  toggleCamera: () => Promise<void>;
  cameras: MediaDeviceInfo[];
  switchCamera: (deviceId: string) => Promise<void>;
  /** My camera, for the self-view. */
  localVideo: MediaStream | null;
  /** Everyone else's audio + video, by user id. */
  remoteStreams: Record<string, MediaStream>;
  decline: () => void;
  hangup: () => void;
  toggleMute: () => void;
  microphones: MediaDeviceInfo[];
  micId: string | null;
  selectMicrophone: (deviceId: string) => Promise<void>;
  /** Group call: ask another staff member to join (it rings them). */
  addPerson: (person: CallPeer) => Promise<boolean>;
  cancelAdd: (userId: string) => void;
  /** Hand the call to another staff member; I leave once they pick up. */
  transferTo: (person: CallPeer) => Promise<boolean>;
  /** Drivers on a call right now, by driver id. */
  onCallByDriver: Record<string, OnCallInfo>;
}

const IDLE: CallState = {
  phase: 'idle',
  callId: null,
  peer: null,
  channelName: '',
  direction: null,
  answeredAt: null,
  muted: false,
  remoteMuted: false,
  reconnecting: false,
  endedText: null,
  moreIncoming: 0,
  recording: false,
  members: [],
  pending: [],
  mutedIds: [],
  maxParticipants: 6,
  invitedBy: null,
  transfer: false,
  callType: 'audio',
  cameraOn: false,
  remoteCamera: [],
  videoCapable: [],
  recordVideo: false,
};

/** Video quality per person: lighter when several people send to everyone (mesh). */
const videoLimitFor = (people: number) =>
  people >= 3 ? { maxBitrate: 200_000, maxFramerate: 12, scale: 2 } : { maxBitrate: 500_000, maxFramerate: 15, scale: 1 };

const cameraErrorText = (err: unknown) => {
  const name = (err as { name?: string })?.name;
  if (name === 'NotAllowedError' || name === 'SecurityError') return 'Camera is blocked — allow it in the browser (lock icon next to the address)';
  if (name === 'NotFoundError' || name === 'OverconstrainedError') return 'No camera found';
  if (name === 'NotReadableError') return 'The camera is in use by another app';
  return 'Could not turn the camera on';
};

/** Camera state from a server roster/view: ids whose camera is on. */
const cameraIds = (camera: Record<string, boolean> | undefined) =>
  Object.entries(camera || {})
    .filter(([, on]) => on)
    .map(([id]) => id);

const CallContext = React.createContext<CallContextValue | null>(null);

export function useCall(): CallContextValue {
  const ctx = React.useContext(CallContext);
  if (!ctx) throw new Error('useCall must be used inside <CallProvider>');
  return ctx;
}

/** The call a driver is on right now (for "On call" marks), or null. Safe outside <CallProvider>. */
export function useDriverOnCall(driverId?: string | null): OnCallInfo | null {
  const ctx = React.useContext(CallContext);
  return (driverId && ctx?.onCallByDriver[driverId]) || null;
}

const ENDED_TEXT: Record<string, string> = {
  completed: 'Call ended',
  missed: 'No answer',
  declined: 'Call declined',
  cancelled: 'Call cancelled',
  busy: 'Busy',
  failed: 'Call failed',
};

const fmt = (sec: number) => `${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, '0')}`;

/** This dashboard user's profile id — the same id the server reads from the login token. */
function myUserId(): string {
  try {
    const token = localStorage.getItem('custom-auth-token') || '';
    const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    return String(payload?.id || '');
  } catch {
    return '';
  }
}

function notifyBrowser(title: string, body: string) {
  if (typeof window === 'undefined' || !('Notification' in window)) return;
  if (!document.hidden || Notification.permission !== 'granted') return;
  try {
    const n = new Notification(title, { body, tag: 'uscitylink-call', requireInteraction: true });
    n.onclick = () => {
      window.focus();
      n.close();
    };
  } catch {
    // some browsers only allow notifications from a service worker
  }
}

const askNotificationPermission = () => {
  if (typeof window !== 'undefined' && 'Notification' in window && Notification.permission === 'default') {
    void Notification.requestPermission();
  }
};

export function CallProvider({ children }: { children: React.ReactNode }): React.JSX.Element {
  const { socket } = useSocket();
  const [saveQuality] = useSaveCallQualityMutation();
  const [state, setState] = React.useState<CallState>(IDLE);
  const [microphones, setMicrophones] = React.useState<MediaDeviceInfo[]>([]);
  const [micId, setMicId] = React.useState<string | null>(null);
  const [onCallByDriver, setOnCallByDriver] = React.useState<Record<string, OnCallInfo>>({});
  const [cameras, setCameras] = React.useState<MediaDeviceInfo[]>([]);
  const [localVideo, setLocalVideo] = React.useState<MediaStream | null>(null);
  const [remoteStreams, setRemoteStreams] = React.useState<Record<string, MediaStream>>({});
  // My camera track (shared by every connection, like the microphone)
  const cameraRef = React.useRef<MediaStreamTrack | null>(null);
  const cameraIdRef = React.useRef<string | null>(null);

  const stateRef = React.useRef(state);
  stateRef.current = state;
  // One connection (and one <audio>) per other person on the call, by their user id
  const enginesRef = React.useRef(new Map<string, WebRtcEngine>());
  const audioBoxRef = React.useRef<HTMLDivElement | null>(null);
  const audiosRef = React.useRef(new Map<string, HTMLAudioElement>());
  // Caller's microphone, opened before ringing, handed to the engine once the call is answered
  const pendingMicRef = React.useRef<MediaStream | null>(null);
  const iceRef = React.useRef<RTCIceServer[]>([]);
  // Signals from someone whose connection doesn't exist yet (by sender)
  const pendingSignals = React.useRef(new Map<string, SignalData[]>());
  const endedTimer = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  // Incoming calls waiting behind the one on screen (several drivers can ring a free dispatcher)
  const incomingQueue = React.useRef<any[]>([]);
  // Recorded call: the connection sending this side's microphone to the server, and that microphone
  const uplinkRef = React.useRef<RecordingUplink | null>(null);
  const micStreamRef = React.useRef<MediaStream | null>(null);
  const recordingRef = React.useRef(false);

  const incomingState = (call: any, more: number): CallState => ({
    ...IDLE,
    phase: 'incoming',
    direction: 'in',
    callId: call.callId,
    peer: call.joinRequest ? call.invitedBy : call.from,
    channelName: call.channelName || '',
    moreIncoming: more,
    recording: !!call.recording,
    invitedBy: call.joinRequest ? call.invitedBy : null,
    transfer: !!call.transfer,
    members: call.joinRequest ? (call.members || []) : [],
    callType: call.type === 'video' ? 'video' : 'audio',
  });

  /** Show the next driver who is still ringing, or go idle. */
  const showNextIncoming = React.useCallback(() => {
    const next = incomingQueue.current.shift();
    if (next) {
      setState(incomingState(next, incomingQueue.current.length));
      playRingtone();
    } else {
      stopTones();
      setState(IDLE);
    }
  }, []);

  const dropQueued = (callId: string) => {
    const before = incomingQueue.current.length;
    incomingQueue.current = incomingQueue.current.filter((c) => c.callId !== callId);
    if (before !== incomingQueue.current.length) patch({ moreIncoming: incomingQueue.current.length });
  };

  const patch = (p: Partial<CallState>) => setState((s) => ({ ...s, ...p }));

  /** Everyone on the call but me, from a server roster. */
  const others = (people: CallPeer[] | undefined) => {
    const me = myUserId();
    return (people || []).filter((p) => p.id !== me);
  };

  const releasePendingMic = () => {
    pendingMicRef.current?.getTracks().forEach((t) => t.stop());
    pendingMicRef.current = null;
  };

  const emit = React.useCallback(
    <T,>(event: string, payload: any): Promise<T> =>
      new Promise((resolve) => {
        if (!socket) return resolve({ ok: false, message: 'Not connected' } as T);
        const timer = setTimeout(() => resolve({ ok: false, message: 'The server did not answer' } as T), 10_000);
        socket.emit(event, payload, (res: T) => {
          clearTimeout(timer);
          resolve(res);
        });
      }),
    [socket]
  );

  const refreshMicrophones = React.useCallback(async () => {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      setMicrophones(devices.filter((d) => d.kind === 'audioinput'));
      setCameras(devices.filter((d) => d.kind === 'videoinput'));
    } catch {
      setMicrophones([]);
    }
  }, []);

  /** Close the connection to one person (they left, or the call ended). */
  const closePeer = (peerId: string) => {
    enginesRef.current.get(peerId)?.close();
    enginesRef.current.delete(peerId);
    pendingSignals.current.delete(peerId);
    const audio = audiosRef.current.get(peerId);
    if (audio) {
      audio.srcObject = null;
      audio.remove();
    }
    audiosRef.current.delete(peerId);
    setRemoteStreams(({ [peerId]: _gone, ...rest }) => rest);
  };

  /** Use [track] as my camera on every connection (null = camera off) and tell the others. */
  const applyCamera = (track: MediaStreamTrack | null, announce: boolean) => {
    cameraRef.current = track;
    setLocalVideo(track ? new MediaStream([track]) : null);
    enginesRef.current.forEach((e) => void e.setCamera(track));
    void uplinkRef.current?.setCamera(track);
    patch({ cameraOn: !!track });
    const { callId } = stateRef.current;
    if (announce && callId) socket?.emit('call:media', { callId, video: !!track });
  };

  const stopCamera = () => {
    cameraRef.current?.stop();
    cameraRef.current = null;
    setLocalVideo(null);
  };

  const teardown = React.useCallback(
    async (endedText: string | null) => {
      stopTones();
      const callId = stateRef.current.callId;
      const first = enginesRef.current.values().next().value as WebRtcEngine | undefined;
      const stats = first ? await first.stats() : null;
      Array.from(enginesRef.current.keys()).forEach(closePeer);
      pendingSignals.current.clear();
      uplinkRef.current?.close();
      uplinkRef.current = null;
      micStreamRef.current?.getTracks().forEach((t) => t.stop());
      micStreamRef.current = null;
      stopCamera();
      setRemoteStreams({});
      recordingRef.current = false;
      if (stats && callId && stateRef.current.answeredAt) void saveQuality({ id: callId, stats }).catch(() => undefined);
      if (endedText) {
        playEndTone();
        patch({ phase: 'ended', endedText, reconnecting: false, pending: [] });
        if (endedTimer.current) clearTimeout(endedTimer.current);
        endedTimer.current = setTimeout(() => setState(IDLE), 2500);
      } else {
        setState(IDLE);
      }
    },
    [saveQuality]
  );

  /**
   * Recorded call: send this side's microphone to the server as soon as the call is answered, in
   * parallel with the call connecting (waiting for "connected" lost the first seconds of a call).
   * The tone and "Recorded" badge come when the call connects.
   */
  const startRecording = React.useCallback(
    (callId: string, localStream: MediaStream) => {
      if (uplinkRef.current) return;
      const track = localStream.getAudioTracks()[0];
      if (!track) return;
      const uplink = new RecordingUplink({
        iceServers: iceRef.current,
        track,
        video: stateRef.current.recordVideo,
        offer: async (sdp) => {
          const res: any = await emit('call:rec_offer', { callId, sdp });
          return res?.ok ? res.sdp : null;
        },
      });
      uplinkRef.current = uplink;
      void uplink.start().then(() => uplink.setCamera(cameraRef.current));
    },
    [emit]
  );

  /** The connection to one other person on the call. The microphone is shared by all of them. */
  const connectTo = React.useCallback(
    (peerId: string, isCaller: boolean, callId: string) => {
      const localStream = micStreamRef.current;
      if (!localStream || enginesRef.current.has(peerId)) return enginesRef.current.get(peerId);
      const engine = new WebRtcEngine({
        iceServers: iceRef.current,
        isCaller,
        localStream,
        stopTracksOnClose: false,
        sendSignal: (data) => socket?.emit('call:signal', { callId, data, to: peerId }),
        onRemoteStream: (stream) => {
          let audio = audiosRef.current.get(peerId);
          if (!audio) {
            audio = document.createElement('audio');
            audio.autoplay = true;
            audioBoxRef.current?.appendChild(audio);
            audiosRef.current.set(peerId, audio);
          }
          audio.srcObject = stream;
          void audio.play().catch(() => undefined);
          // New object each time so the video tiles re-render when their video track arrives
          setRemoteStreams((all) => ({ ...all, [peerId]: stream }));
        },
        onState: (s) => {
          if (s === 'connected') {
            stopTones();
            if (recordingRef.current && stateRef.current.phase !== 'active') playRecordingTone();
            patch({ phase: 'active', reconnecting: false });
          } else if (s === 'reconnecting') {
            patch({ reconnecting: true });
          } else if (s === 'failed') {
            if (enginesRef.current.size <= 1) {
              toast.error('The call connection was lost');
              socket?.emit('call:end', { callId });
            } else {
              // Group call: only the link to this person broke; the server drops them if they're gone
              closePeer(peerId);
            }
          }
        },
      });
      enginesRef.current.set(peerId, engine);
      void engine.setVideoLimit(videoLimitFor(stateRef.current.members.length + 1));
      if (cameraRef.current) void engine.setCamera(cameraRef.current);
      // Signals that arrived before this connection existed
      const queued = pendingSignals.current.get(peerId) || [];
      pendingSignals.current.delete(peerId);
      void engine.start().then(() => queued.forEach((d) => void engine.handleSignal(d)));
      return engine;
    },
    [socket]
  );

  /** The call was answered: keep the microphone, start recording, connect to [peers]. */
  const beginMedia = React.useCallback(
    (mic: MediaStream, callId: string, recording: boolean, peers: string[], isCaller: boolean) => {
      micStreamRef.current = mic;
      recordingRef.current = recording;
      if (recording) startRecording(callId, mic);
      peers.forEach((id) => connectTo(id, isCaller, callId));
    },
    [connectTo, startRecording]
  );

  // ---------- actions ----------

  const startCall = React.useCallback(
    async (driver: { id: string; name: string }, opts: { video?: boolean } = {}) => {
      if (stateRef.current.phase !== 'idle' && stateRef.current.phase !== 'ended') {
        toast.info('Finish the current call first');
        return;
      }
      askNotificationPermission();
      let mic: MediaStream;
      try {
        mic = await getMicrophone(micId || undefined);
      } catch (err) {
        toast.error(microphoneErrorText(err, 'make calls'));
        return;
      }
      let camera: MediaStreamTrack | null = null;
      if (opts.video) {
        try {
          camera = await getCamera(cameraIdRef.current || undefined);
        } catch (err) {
          // Staff without a camera still make video calls: the driver's camera is what matters,
          // and they see a blank tile for this side
          toast.info(`${cameraErrorText(err)} — you'll see the driver; they'll see a blank screen for you`);
        }
      }
      void refreshMicrophones();
      const peer: CallPeer = { id: driver.id, name: driver.name, role: 'driver' };
      const callType = opts.video ? 'video' : 'audio';
      setState({ ...IDLE, phase: 'outgoing', direction: 'out', peer, members: [peer], callType });
      if (camera) applyCamera(camera, false);
      // group / video: what this dashboard can do (older driver apps can't — see the server)
      const res: any = await emit('call:invite', {
        driverId: driver.id,
        group: true,
        video: true,
        type: callType,
      });
      if (!res?.ok) {
        mic.getTracks().forEach((t) => t.stop());
        stopCamera();
        const text = res?.error === 'busy' ? 'Busy' : res?.error === 'unavailable' ? 'Unavailable' : null;
        if (text) {
          patch({ phase: 'ended', endedText: `${driver.name} is ${text.toLowerCase()}`, callId: res?.callId || null });
          playEndTone();
          endedTimer.current = setTimeout(() => setState(IDLE), 2500);
        } else {
          setState(IDLE);
        }
        toast.error(res?.message || 'Could not start the call');
        return;
      }
      iceRef.current = res.iceServers || [];
      patch({
        callId: res.callId,
        channelName: res.call?.channelName || '',
        recording: !!res.call?.recording,
        recordVideo: !!res.call?.recordVideo,
        maxParticipants: res.call?.maxParticipants || 6,
      });
      pendingMicRef.current = mic;
      playRingback();
    },
    [emit, micId, refreshMicrophones]
  );

  const accept = React.useCallback(async (opts: { video?: boolean } = {}) => {
    const { callId, phase } = stateRef.current;
    if (!callId || phase !== 'incoming') return;
    stopTones();
    let mic: MediaStream;
    try {
      mic = await getMicrophone(micId || undefined);
    } catch (err) {
      toast.error(microphoneErrorText(err, 'answer calls'));
      socket?.emit('call:decline', { callId });
      setState(IDLE);
      return;
    }
    let camera: MediaStreamTrack | null = null;
    if (opts.video) {
      try {
        camera = await getCamera(cameraIdRef.current || undefined);
      } catch (err) {
        toast.info(`${cameraErrorText(err)} — you'll see them; they'll see a blank screen for you`);
      }
    }
    patch({ phase: 'connecting' });
    const res: any = await emit('call:accept', { callId, group: true, videoCapable: true, camera: !!camera });
    if (!res?.ok) {
      mic.getTracks().forEach((t) => t.stop());
      camera?.stop();
      toast.info(res?.message || 'This call has ended');
      setState(IDLE);
      return;
    }
    iceRef.current = res.iceServers || [];
    incomingQueue.current = [];
    const members = others(res.call?.members);
    const joining = !!stateRef.current.invitedBy;
    patch({
      answeredAt: res.call?.answeredAt || Date.now(),
      moreIncoming: 0,
      recording: !!res.call?.recording,
      members,
      pending: others(res.call?.pending),
      maxParticipants: res.call?.maxParticipants || 6,
      peer: joining ? stateRef.current.peer : res.call?.from || stateRef.current.peer,
      remoteCamera: cameraIds(res.call?.camera).filter((id) => id !== myUserId()),
      videoCapable: res.call?.videoCapable || [],
      recordVideo: !!res.call?.recordVideo,
    });
    if (camera) applyCamera(camera, false);
    void refreshMicrophones();
    // Answering a call: the caller sends the offer. Joining a group call: I offer to everyone on it.
    beginMedia(mic, callId, !!res.call?.recording, members.map((m) => m.id), joining);
  }, [beginMedia, emit, micId, refreshMicrophones, socket]);

  const decline = React.useCallback(() => {
    const { callId } = stateRef.current;
    if (callId) socket?.emit('call:decline', { callId });
    showNextIncoming();
  }, [socket, showNextIncoming]);

  const hangup = React.useCallback(() => {
    const { callId } = stateRef.current;
    if (callId) socket?.emit('call:end', { callId });
    releasePendingMic();
    // call:ended from the server finishes the teardown; this covers a lost connection
    const { answeredAt, phase } = stateRef.current;
    const talked = phase === 'active' && answeredAt ? Math.round((Date.now() - answeredAt) / 1000) : 0;
    void teardown(answeredAt ? (talked ? `Call ended · ${fmt(talked)}` : 'Call ended') : 'Call cancelled');
  }, [socket, teardown]);

  const toggleMute = React.useCallback(() => {
    const muted = !stateRef.current.muted;
    micStreamRef.current?.getAudioTracks().forEach((t) => (t.enabled = !muted));
    patch({ muted });
    if (stateRef.current.callId) socket?.emit('call:media', { callId: stateRef.current.callId, muted });
  }, [socket]);

  const toggleCamera = React.useCallback(async () => {
    if (!stateRef.current.callId) return;
    if (cameraRef.current) {
      stopCamera();
      applyCamera(null, true);
      return;
    }
    try {
      const track = await getCamera(cameraIdRef.current || undefined);
      applyCamera(track, true);
      void refreshMicrophones();
    } catch (err) {
      toast.error(cameraErrorText(err));
    }
  }, [refreshMicrophones, socket]);

  const switchCamera = React.useCallback(async (deviceId: string) => {
    cameraIdRef.current = deviceId;
    if (!cameraRef.current) return;
    try {
      const track = await getCamera(deviceId);
      cameraRef.current.stop();
      applyCamera(track, false);
    } catch (err) {
      toast.error(cameraErrorText(err));
    }
  }, [socket]);

  const selectMicrophone = React.useCallback(async (deviceId: string) => {
    setMicId(deviceId);
    const stream = micStreamRef.current;
    if (!stream) return;
    try {
      const fresh = await getMicrophone(deviceId);
      const track = fresh.getAudioTracks()[0];
      track.enabled = !stateRef.current.muted;
      await Promise.all(Array.from(enginesRef.current.values()).map((e) => e.replaceTrack(track)));
      await uplinkRef.current?.replaceTrack(track);
      stream.getAudioTracks().forEach((t) => {
        t.stop();
        stream.removeTrack(t);
      });
      stream.addTrack(track);
    } catch {
      toast.error('Could not switch to that microphone');
    }
  }, []);

  const addPerson = React.useCallback(
    async (person: CallPeer) => {
      const { callId } = stateRef.current;
      if (!callId) return false;
      const res: any = await emit('call:add', { callId, userId: person.id });
      if (!res?.ok) {
        toast.error(res?.message || 'Could not add them');
        return false;
      }
      toast.info(`Calling ${person.name} to join…`);
      return true;
    },
    [emit]
  );

  const transferTo = React.useCallback(
    async (person: CallPeer) => {
      const { callId } = stateRef.current;
      if (!callId) return false;
      const res: any = await emit('call:transfer', { callId, userId: person.id });
      if (!res?.ok) {
        toast.error(res?.message || 'Could not transfer the call');
        return false;
      }
      toast.info(`Transferring to ${person.name}… you'll leave the call when they pick up`);
      return true;
    },
    [emit]
  );

  const cancelAdd = React.useCallback(
    (userId: string) => {
      const { callId } = stateRef.current;
      if (callId) socket?.emit('call:add_cancel', { callId, userId });
    },
    [socket]
  );

  // ---------- server events ----------

  useSocketEvent('call:incoming', (call: any) => {
    const s = stateRef.current;
    if (s.callId === call.callId || incomingQueue.current.some((c) => c.callId === call.callId)) return;
    if (s.phase === 'incoming') {
      // Another driver is calling too: line them up behind the card on screen
      incomingQueue.current.push(call);
      patch({ moreIncoming: incomingQueue.current.length });
      return;
    }
    if (s.phase !== 'idle' && s.phase !== 'ended') return; // on a call; the server doesn't ring busy dispatchers
    if (endedTimer.current) clearTimeout(endedTimer.current);
    setState(incomingState(call, 0));
    playRingtone();
    const title = call.joinRequest ? `${call.invitedBy?.name} asks you to join a call` : `Incoming call · ${call.from?.name}`;
    notifyBrowser(title, call.channelName ? `${call.channelName} — open USCityLink to answer` : 'Open USCityLink to answer');
  });

  useSocketEvent('call:accepted', ({ callId, by, camera, videoCapable }: any) => {
    const s = stateRef.current;
    if (s.callId !== callId || s.phase !== 'outgoing') return;
    stopTones();
    const mic = pendingMicRef.current;
    pendingMicRef.current = null;
    const peer: CallPeer = by ? { ...by } : s.peer!;
    patch({
      phase: 'connecting',
      answeredAt: Date.now(),
      peer,
      members: [peer],
      remoteCamera: cameraIds(camera).filter((id) => id !== myUserId()),
      videoCapable: videoCapable || [],
    });
    if (!mic) {
      socket?.emit('call:end', { callId });
      return;
    }
    beginMedia(mic, callId, s.recording, [peer.id], true);
  });

  useSocketEvent('call:ringing', () => undefined);

  useSocketEvent('call:answered_elsewhere', ({ callId, by }: any) => {
    dropQueued(callId);
    const s = stateRef.current;
    if (s.callId !== callId || s.phase !== 'incoming') return;
    toast.info(`${by?.name || 'Another dispatcher'} answered ${s.peer?.name || 'the call'}`);
    showNextIncoming();
  });

  // Group call: someone joined (they send me the offer) or left
  useSocketEvent('call:member_joined', ({ callId, person }: any) => {
    if (stateRef.current.callId !== callId || !person?.id) return;
    connectTo(person.id, false, callId);
    toast.info(`${person.name} joined the call`);
  });

  useSocketEvent('call:member_left', ({ callId, person }: any) => {
    if (stateRef.current.callId !== callId || !person?.id) return;
    closePeer(person.id);
    patch({ mutedIds: stateRef.current.mutedIds.filter((id) => id !== person.id) });
    toast.info(`${person.name} left the call`);
  });

  useSocketEvent('call:participants', ({ callId, members, pending, max, camera, videoCapable }: any) => {
    if (stateRef.current.callId !== callId) return;
    const me = myUserId();
    const nextMembers = others(members);
    patch({
      members: nextMembers,
      pending: others(pending),
      maxParticipants: max || 6,
      ...(camera ? { remoteCamera: cameraIds(camera).filter((id) => id !== me) } : {}),
      ...(videoCapable ? { videoCapable } : {}),
    });
    // Everyone sends video to everyone: lighter video once 3+ are on the call
    const limit = videoLimitFor(nextMembers.length + 1);
    enginesRef.current.forEach((e) => void e.setVideoLimit(limit));
  });

  // Transfer: the other dispatcher picked up (call:ended follows for me), or didn't
  useSocketEvent('call:transferred', ({ callId, to }: any) => {
    if (stateRef.current.callId === callId) toast.success(`Call transferred to ${to?.name || 'them'}`);
  });

  useSocketEvent('call:transfer_failed', ({ callId, person, reason }: any) => {
    if (stateRef.current.callId !== callId) return;
    toast.warning(`${person?.name || 'They'} ${reason === 'declined' ? 'declined' : "didn't answer"} — you're still on the call`);
  });

  // Who is on a call across the company (server sends the list on connect, then on every change)
  const applyOnCall = React.useCallback((calls: OnCallInfo[] | undefined) => {
    const byDriver: Record<string, OnCallInfo> = {};
    (calls || []).forEach((c) => (byDriver[c.driverId] = c));
    setOnCallByDriver(byDriver);
  }, []);
  useSocketEvent('calls:on_call', ({ calls }: { calls: OnCallInfo[] }) => applyOnCall(calls));

  // Ask for the current list too: the one sent on connect can arrive before this page listens
  React.useEffect(() => {
    if (!socket) return undefined;
    const fetchList = () => socket.emit('calls:on_call_get', {}, (res: any) => res?.ok && applyOnCall(res.calls));
    if (socket.connected) fetchList();
    socket.on('connect', fetchList);
    return () => {
      socket.off('connect', fetchList);
    };
  }, [socket, applyOnCall]);

  useSocketEvent('call:signal', ({ callId, from, data }: any) => {
    if (stateRef.current.callId !== callId) return;
    // Older servers don't say who sent it: on a 1-to-1 call it's the only other person
    const sender = from || Array.from(enginesRef.current.keys())[0] || stateRef.current.peer?.id;
    if (!sender) return;
    const engine = enginesRef.current.get(sender);
    if (engine) void engine.handleSignal(data);
    else pendingSignals.current.set(sender, [...(pendingSignals.current.get(sender) || []), data]);
  });

  useSocketEvent('call:media', ({ callId, from, muted, video }: any) => {
    const s = stateRef.current;
    if (s.callId !== callId) return;
    const id = from || s.peer?.id || '';
    const mutedIds = muted ? Array.from(new Set([...s.mutedIds, id])) : s.mutedIds.filter((m) => m !== id);
    const remoteCamera =
      typeof video === 'boolean'
        ? video
          ? Array.from(new Set([...s.remoteCamera, id]))
          : s.remoteCamera.filter((m) => m !== id)
        : s.remoteCamera;
    patch({ mutedIds, remoteMuted: mutedIds.length > 0, remoteCamera });
  });

  useSocketEvent('call:peer_reconnecting', ({ callId }: any) => {
    if (stateRef.current.callId === callId) patch({ reconnecting: true });
  });

  useSocketEvent('call:peer_reconnected', ({ callId, from }: any) => {
    if (stateRef.current.callId !== callId) return;
    const engine = from ? enginesRef.current.get(from) : undefined;
    if (engine) engine.restartIce();
    else enginesRef.current.forEach((e) => e.restartIce());
  });

  // Our own socket came back: the server still has the call — renegotiate the network paths.
  // After a page reload there is no audio connection left to resume, so end it cleanly.
  useSocketEvent('call:resume', ({ callId }: any) => {
    if (enginesRef.current.size && stateRef.current.callId === callId) enginesRef.current.forEach((e) => e.restartIce());
    else socket?.emit('call:end', { callId });
  });

  useSocketEvent('call:ended', ({ callId, status, reason, durationSec }: any) => {
    dropQueued(callId);
    const s = stateRef.current;
    if (s.callId !== callId || s.phase === 'ended') return;
    if (s.phase === 'incoming') {
      // The driver hung up, nobody answered in time, or a join request was taken back
      showNextIncoming();
      return;
    }
    releasePendingMic();
    const text =
      reason === 'transferred'
        ? 'Call transferred'
        : status === 'completed' && durationSec
          ? `Call ended · ${fmt(durationSec)}`
          : ENDED_TEXT[status] || 'Call ended';
    void teardown(text);
  });

  React.useEffect(
    () => () => {
      stopTones();
      uplinkRef.current?.close();
      enginesRef.current.forEach((e) => e.close());
      micStreamRef.current?.getTracks().forEach((t) => t.stop());
    },
    []
  );

  const value: CallContextValue = {
    ...state,
    startCall,
    accept,
    decline,
    hangup,
    toggleMute,
    microphones,
    micId,
    selectMicrophone,
    addPerson,
    cancelAdd,
    transferTo,
    onCallByDriver,
    toggleCamera,
    cameras,
    switchCamera,
    localVideo,
    remoteStreams,
  };

  return (
    <CallContext.Provider value={value}>
      {children}
      {/* Remote audio, one element per person; autoplay is allowed because answering/calling was a click */}
      <div ref={audioBoxRef} style={{ display: 'none' }} />
    </CallContext.Provider>
  );
}

export { fmt as formatCallDuration, ENDED_TEXT };
