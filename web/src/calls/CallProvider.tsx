'use client';

import * as React from 'react';
import { toast } from 'react-toastify';

import { useSocket } from '@/lib/socketProvider';
import { useSocketEvent } from '@/hooks/use-socket-event';
import { useSaveCallQualityMutation } from '@/redux/CallApiSlice';

import { playEndTone, playRingback, playRingtone, stopTones } from './sounds';
import { getMicrophone, SignalData, WebRtcEngine } from './webrtcEngine';

// Voice calls on the web dashboard. One call at a time; the server (server/src/calls) decides who
// rings and when a call ends, this provider runs the WebRTC side and the UI state.
//
//   idle ─startCall→ outgoing ─call:accepted→ connecting ─media up→ active ─call:ended→ ended → idle
//   idle ─call:incoming→ incoming ─accept→ connecting → active …

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
}

interface CallContextValue extends CallState {
  startCall: (driver: { id: string; name: string }) => Promise<void>;
  accept: () => Promise<void>;
  decline: () => void;
  hangup: () => void;
  toggleMute: () => void;
  microphones: MediaDeviceInfo[];
  micId: string | null;
  selectMicrophone: (deviceId: string) => Promise<void>;
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
};

const CallContext = React.createContext<CallContextValue | null>(null);

export function useCall(): CallContextValue {
  const ctx = React.useContext(CallContext);
  if (!ctx) throw new Error('useCall must be used inside <CallProvider>');
  return ctx;
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

  const stateRef = React.useRef(state);
  stateRef.current = state;
  const engineRef = React.useRef<WebRtcEngine | null>(null);
  // Caller's microphone, opened before ringing, handed to the engine once the call is answered
  const pendingMicRef = React.useRef<MediaStream | null>(null);
  const audioRef = React.useRef<HTMLAudioElement | null>(null);
  const iceRef = React.useRef<RTCIceServer[]>([]);
  const pendingSignals = React.useRef<SignalData[]>([]);
  const endedTimer = React.useRef<ReturnType<typeof setTimeout> | null>(null);
  // Incoming calls waiting behind the one on screen (several drivers can ring a free dispatcher)
  const incomingQueue = React.useRef<any[]>([]);

  const incomingState = (call: any, more: number): CallState => ({
    ...IDLE,
    phase: 'incoming',
    direction: 'in',
    callId: call.callId,
    peer: call.from,
    channelName: call.channelName || '',
    moreIncoming: more,
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
    } catch {
      setMicrophones([]);
    }
  }, []);

  const teardown = React.useCallback(
    async (endedText: string | null) => {
      stopTones();
      const engine = engineRef.current;
      const callId = stateRef.current.callId;
      engineRef.current = null;
      pendingSignals.current = [];
      if (engine) {
        const stats = await engine.stats();
        engine.close();
        if (callId && stateRef.current.answeredAt) void saveQuality({ id: callId, stats }).catch(() => undefined);
      }
      if (audioRef.current) audioRef.current.srcObject = null;
      if (endedText) {
        playEndTone();
        patch({ phase: 'ended', endedText, reconnecting: false });
        if (endedTimer.current) clearTimeout(endedTimer.current);
        endedTimer.current = setTimeout(() => setState(IDLE), 2500);
      } else {
        setState(IDLE);
      }
    },
    [saveQuality]
  );

  const createEngine = React.useCallback(
    (isCaller: boolean, localStream: MediaStream, callId: string) => {
      const engine = new WebRtcEngine({
        iceServers: iceRef.current,
        isCaller,
        localStream,
        sendSignal: (data) => socket?.emit('call:signal', { callId, data }),
        onRemoteStream: (stream) => {
          if (audioRef.current) {
            audioRef.current.srcObject = stream;
            void audioRef.current.play().catch(() => undefined);
          }
        },
        onState: (s) => {
          if (s === 'connected') {
            stopTones();
            patch({ phase: 'active', reconnecting: false });
          } else if (s === 'reconnecting') {
            patch({ reconnecting: true });
          } else if (s === 'failed') {
            toast.error('The call connection was lost');
            socket?.emit('call:end', { callId });
          }
        },
      });
      engineRef.current = engine;
      // Signals that arrived while the microphone was opening
      const queued = pendingSignals.current.splice(0);
      queued.forEach((d) => void engine.handleSignal(d));
      return engine;
    },
    [socket]
  );

  // ---------- actions ----------

  const startCall = React.useCallback(
    async (driver: { id: string; name: string }) => {
      if (stateRef.current.phase !== 'idle' && stateRef.current.phase !== 'ended') {
        toast.info('Finish the current call first');
        return;
      }
      askNotificationPermission();
      let mic: MediaStream;
      try {
        mic = await getMicrophone(micId || undefined);
      } catch {
        toast.error('Allow microphone access in the browser to make calls');
        return;
      }
      void refreshMicrophones();
      setState({ ...IDLE, phase: 'outgoing', direction: 'out', peer: { id: driver.id, name: driver.name, role: 'driver' } });
      const res: any = await emit('call:invite', { driverId: driver.id });
      if (!res?.ok) {
        mic.getTracks().forEach((t) => t.stop());
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
      patch({ callId: res.callId, channelName: res.call?.channelName || '' });
      pendingMicRef.current = mic;
      playRingback();
    },
    [emit, micId, refreshMicrophones]
  );

  const accept = React.useCallback(async () => {
    const { callId, phase } = stateRef.current;
    if (!callId || phase !== 'incoming') return;
    stopTones();
    let mic: MediaStream;
    try {
      mic = await getMicrophone(micId || undefined);
    } catch {
      toast.error('Allow microphone access in the browser to answer calls');
      socket?.emit('call:decline', { callId });
      setState(IDLE);
      return;
    }
    patch({ phase: 'connecting' });
    const res: any = await emit('call:accept', { callId });
    if (!res?.ok) {
      mic.getTracks().forEach((t) => t.stop());
      toast.info(res?.message || 'This call has ended');
      setState(IDLE);
      return;
    }
    iceRef.current = res.iceServers || [];
    incomingQueue.current = [];
    patch({ answeredAt: res.call?.answeredAt || Date.now(), moreIncoming: 0 });
    void refreshMicrophones();
    const engine = createEngine(false, mic, callId);
    await engine.start();
  }, [createEngine, emit, micId, refreshMicrophones, socket]);

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
    engineRef.current?.setMuted(muted);
    patch({ muted });
    if (stateRef.current.callId) socket?.emit('call:media', { callId: stateRef.current.callId, muted });
  }, [socket]);

  const selectMicrophone = React.useCallback(async (deviceId: string) => {
    setMicId(deviceId);
    try {
      await engineRef.current?.switchMicrophone(deviceId, stateRef.current.muted);
    } catch {
      toast.error('Could not switch to that microphone');
    }
  }, []);

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
    notifyBrowser(`Incoming call · ${call.from?.name}`, call.channelName ? `${call.channelName} — open USCityLink to answer` : 'Open USCityLink to answer');
  });

  useSocketEvent('call:accepted', async ({ callId, by }: any) => {
    const s = stateRef.current;
    if (s.callId !== callId || s.phase !== 'outgoing') return;
    stopTones();
    const mic = pendingMicRef.current;
    pendingMicRef.current = null;
    patch({ phase: 'connecting', answeredAt: Date.now(), peer: by ? { ...by } : s.peer });
    if (!mic) {
      socket?.emit('call:end', { callId });
      return;
    }
    const engine = createEngine(true, mic, callId);
    await engine.start();
  });

  useSocketEvent('call:ringing', () => undefined);

  useSocketEvent('call:answered_elsewhere', ({ callId, by }: any) => {
    dropQueued(callId);
    const s = stateRef.current;
    if (s.callId !== callId || s.phase !== 'incoming') return;
    toast.info(`${by?.name || 'Another dispatcher'} answered ${s.peer?.name || 'the call'}`);
    showNextIncoming();
  });

  useSocketEvent('call:signal', ({ callId, data }: any) => {
    if (stateRef.current.callId !== callId) return;
    if (engineRef.current) void engineRef.current.handleSignal(data);
    else pendingSignals.current.push(data);
  });

  useSocketEvent('call:media', ({ callId, muted }: any) => {
    if (stateRef.current.callId === callId) patch({ remoteMuted: !!muted });
  });

  useSocketEvent('call:peer_reconnecting', ({ callId }: any) => {
    if (stateRef.current.callId === callId) patch({ reconnecting: true });
  });

  useSocketEvent('call:peer_reconnected', ({ callId }: any) => {
    if (stateRef.current.callId === callId) engineRef.current?.restartIce();
  });

  // Our own socket came back: the server still has the call — renegotiate the network path.
  // After a page reload there is no audio connection left to resume, so end it cleanly.
  useSocketEvent('call:resume', ({ callId }: any) => {
    if (engineRef.current && stateRef.current.callId === callId) engineRef.current.restartIce();
    else socket?.emit('call:end', { callId });
  });

  useSocketEvent('call:ended', ({ callId, status, durationSec }: any) => {
    dropQueued(callId);
    const s = stateRef.current;
    if (s.callId !== callId || s.phase === 'ended') return;
    if (s.phase === 'incoming') {
      // The driver hung up or nobody answered in time
      showNextIncoming();
      return;
    }
    releasePendingMic();
    const text =
      status === 'completed' && durationSec ? `Call ended · ${fmt(durationSec)}` : ENDED_TEXT[status] || 'Call ended';
    void teardown(text);
  });

  React.useEffect(
    () => () => {
      stopTones();
      engineRef.current?.close();
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
  };

  return (
    <CallContext.Provider value={value}>
      {children}
      {/* Remote audio; autoplay is allowed because answering/calling was a click */}
      <audio autoPlay ref={audioRef} style={{ display: 'none' }} />
    </CallContext.Provider>
  );
}

export { fmt as formatCallDuration, ENDED_TEXT };
