import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// One WebRTC audio connection to the other person on a call — the Flutter twin of
/// web/src/calls/webrtcEngine.ts, with the same rules:
///   * only the CALLER sends offers (first offer after "call:accepted", and ICE restarts);
///     the callee answers, or asks for a restart with {type: 'restart-request'};
///   * ICE candidates that arrive before the remote description are queued.
/// Group calls use one engine per other person (CallService), all sharing the microphone.
///
/// Video without renegotiation (same as the web): the caller's offer carries a video slot; the
/// callee switches the offered slot to send+receive before answering. Camera on/off = swap the track
/// in that slot (setCamera). An older app offering audio only simply has no video slot.
enum EngineState { connecting, connected, reconnecting, failed, closed }

class WebRtcEngine {
  WebRtcEngine({
    required this.iceServers,
    required this.isCaller,
    required this.sendSignal,
    required this.onState,
    this.ownsStream = true,
    this.onRemoteStream,
  });

  final List<Map<String, dynamic>> iceServers;
  final bool isCaller;

  /// Group calls share one microphone between the connections to each person: closing one of them
  /// must not stop it.
  final bool ownsStream;
  final void Function(Map<String, dynamic> data) sendSignal;
  final void Function(EngineState state) onState;

  /// The other person's audio + video in one stream (it gains a video track when theirs arrives).
  final void Function(MediaStream stream)? onRemoteStream;

  static const _maxRestarts = 6;
  MediaStreamTrack? _camera;
  ({int maxBitrate, int maxFramerate, double scale})? _videoLimit;
  final Map<String, MediaStreamTrack> _remoteTracks = {}; // by kind
  int _remoteVersion = 0;

  RTCPeerConnection? _pc;
  MediaStream? _local;
  final List<RTCIceCandidate> _pending = [];
  int _restarts = 0;
  Timer? _restartTimer;
  bool _closed = false;
  EngineState _state = EngineState.connecting;
  // Signals can arrive while start() is still creating the connection (the other side sends its
  // offer the moment the call is answered). Handled in order once it's ready, never dropped.
  bool _started = false;
  final List<Map<String, dynamic>> _early = [];
  Future<void> _signals = Future.value();
  Timer? _watchdog;

  int get iceRestarts => _restarts;

  /// This side's microphone (what the call recording sends to the server).
  MediaStream? get localStream => _local;

  static Future<MediaStream> openMicrophone() => navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

  /// The camera for video calls (640×360, 15 fps — faces, light on mobile data).
  static Future<MediaStream> openCamera({bool front = true}) => navigator.mediaDevices.getUserMedia({
        'audio': false,
        'video': {
          'facingMode': front ? 'user' : 'environment',
          'width': {'ideal': 640},
          'height': {'ideal': 360},
          'frameRate': {'ideal': 15, 'max': 24},
        },
      });

  Future<void> start(MediaStream localStream) async {
    _local = localStream;
    final pc = await createPeerConnection({
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
    });
    _pc = pc;
    for (final track in localStream.getAudioTracks()) {
      await pc.addTrack(track, localStream);
    }
    // The caller's offer carries the video slot (the callee gets it from the offer)
    if (isCaller) {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    }
    // Remote audio plays through the call audio route by itself; video needs the stream for a renderer
    pc.onTrack = (event) async {
      try {
        // A fresh stream with all of their tracks each time: a renderer already showing a stream
        // may not start drawing a video track added to it later
        _remoteTracks[event.track.kind ?? 'audio'] = event.track;
        final remote = await createLocalMediaStream('remote-${identityHashCode(this)}-${_remoteVersion++}');
        for (final t in _remoteTracks.values) {
          await remote.addTrack(t);
        }
        onRemoteStream?.call(remote);
      } catch (e) {
        // ignore: avoid_print
        print('[call] remote track failed: $e');
      }
    };
    pc.onIceCandidate = (c) {
      if (c.candidate != null) {
        sendSignal({
          'type': 'candidate',
          'candidate': {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex},
        });
      }
    };
    // Remote audio plays through the call audio route automatically (no renderer needed)
    pc.onConnectionState = _onConnectionState;
    _started = true;
    for (final s in _early) {
      _signals = _signals.then((_) => _handleSignal(s));
    }
    _early.clear();
    _startWatchdog();
    if (isCaller) await _offer(false);
  }

  /// A call that never gets connected must not sit on "Connecting…" forever. The answering side
  /// asks for the offer again if it hasn't arrived (it can be lost while the app was waking up);
  /// after [_connectTimeout] the call is given up as failed so the user gets a clear message.
  static const _connectTimeout = Duration(seconds: 30);

  void _startWatchdog() {
    final started = DateTime.now();
    var asked = 0;
    _watchdog = Timer.periodic(const Duration(seconds: 5), (t) async {
      if (_closed || _state == EngineState.connected) return t.cancel();
      if (DateTime.now().difference(started) >= _connectTimeout) {
        t.cancel();
        return _setState(EngineState.failed);
      }
      final pc = _pc;
      if (!isCaller && asked < 3 && pc != null && await pc.getRemoteDescription() == null) {
        asked++;
        sendSignal({'type': 'restart-request'});
      }
    });
  }

  /// Signals are handled one at a time in arrival order (an ICE candidate must never race the offer).
  Future<void> handleSignal(Map<String, dynamic> data) {
    if (!_started) {
      _early.add(data);
      return Future.value();
    }
    return _signals = _signals.then((_) => _handleSignal(data));
  }

  Future<void> _handleSignal(Map<String, dynamic> data) async {
    final pc = _pc;
    if (_closed || pc == null) return;
    try {
      switch (data['type']) {
        case 'offer':
          await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));
          // Callee: send video back in the slot the caller offered (and attach a camera already on)
          final video = await _videoTransceiver();
          if (video != null) await video.setDirection(TransceiverDirection.SendRecv);
          await _applyCamera();
          await _flush();
          final answer = await pc.createAnswer();
          await pc.setLocalDescription(answer);
          sendSignal({'type': 'answer', 'sdp': answer.sdp});
          break;
        case 'answer':
          if (pc.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) return;
          await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
          await _flush();
          break;
        case 'candidate':
          final c = Map<String, dynamic>.from(data['candidate'] ?? {});
          final candidate = RTCIceCandidate(c['candidate'], c['sdpMid'], (c['sdpMLineIndex'] as num?)?.toInt());
          if (await pc.getRemoteDescription() != null) {
            await pc.addCandidate(candidate);
          } else {
            _pending.add(candidate);
          }
          break;
        case 'restart-request':
          if (isCaller) restartIce();
          break;
      }
    } catch (e) {
      // ignore: avoid_print
      print('[call] signal ${data['type']} failed: $e');
    }
  }

  Future<RTCRtpTransceiver?> _videoTransceiver() async {
    final pc = _pc;
    if (pc == null) return null;
    for (final t in await pc.getTransceivers()) {
      if (t.receiver.track?.kind == 'video') return t;
    }
    return null;
  }

  /// Camera on (a track) or off (null). No renegotiation: the video slot just changes track.
  Future<void> setCamera(MediaStreamTrack? track) async {
    _camera = track;
    await _applyCamera();
  }

  /// Lighter video in big group calls (everyone sends to everyone).
  Future<void> setVideoLimit({required int maxBitrate, required int maxFramerate, required double scale}) async {
    _videoLimit = (maxBitrate: maxBitrate, maxFramerate: maxFramerate, scale: scale);
    await _applyCamera();
  }

  Future<void> _applyCamera() async {
    if (_closed) return;
    try {
      final sender = (await _videoTransceiver())?.sender;
      if (sender == null) return;
      await sender.replaceTrack(_camera);
      final limit = _videoLimit;
      if (_camera != null && limit != null) {
        final params = sender.parameters;
        final encodings = params.encodings ?? [];
        if (encodings.isEmpty) encodings.add(RTCRtpEncoding());
        encodings[0]
          ..maxBitrate = limit.maxBitrate
          ..maxFramerate = limit.maxFramerate
          ..scaleResolutionDownBy = limit.scale;
        params.encodings = encodings;
        await sender.setParameters(params);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[call] camera update failed: $e');
    }
  }

  void setMuted(bool muted) {
    for (final t in _local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
  }

  Future<void> setSpeaker(bool on) => Helper.setSpeakerphoneOn(on);

  /// Network changed (Wi-Fi ↔ mobile data, tower hand-off) or the other side reconnected.
  void restartIce() {
    if (_closed) return;
    if (_restarts >= _maxRestarts) return _setState(EngineState.failed);
    _restarts++;
    _setState(EngineState.reconnecting);
    if (isCaller) {
      _offer(true);
    } else {
      sendSignal({'type': 'restart-request'});
    }
  }

  /// End-of-call summary saved on the call (POST /calls/:id/quality) for troubleshooting.
  Future<Map<String, dynamic>> stats(String platform) async {
    final out = <String, dynamic>{'iceRestarts': _restarts, 'platform': platform};
    final pc = _pc;
    if (pc == null) return out;
    try {
      final reports = await pc.getStats();
      final byId = {for (final r in reports) r.id: r};
      for (final r in reports) {
        final v = r.values;
        if (r.type == 'candidate-pair' && (v['selected'] == true || v['nominated'] == true) && v['state'] == 'succeeded') {
          final rtt = v['currentRoundTripTime'];
          if (rtt is num) out['rttMs'] = (rtt * 1000).round();
          out['bytesSent'] = v['bytesSent'];
          out['bytesReceived'] = v['bytesReceived'];
          final local = byId[v['localCandidateId']]?.values['candidateType'];
          final remote = byId[v['remoteCandidateId']]?.values['candidateType'];
          out['localCandidate'] = local;
          out['remoteCandidate'] = remote;
          out['relay'] = local == 'relay' || remote == 'relay';
        }
        if (r.type == 'inbound-rtp' && v['kind'] == 'audio') {
          final jitter = v['jitter'];
          if (jitter is num) out['jitterMs'] = (jitter * 1000).round();
          final lost = (v['packetsLost'] as num?) ?? 0;
          final got = (v['packetsReceived'] as num?) ?? 0;
          out['packetLossPct'] = (got + lost) > 0 ? ((lost / (got + lost)) * 1000).round() / 10 : 0;
          final codec = byId[v['codecId']]?.values['mimeType'];
          if (codec != null) out['codec'] = codec;
        }
      }
    } catch (_) {
      // best effort
    }
    return out;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _restartTimer?.cancel();
    _watchdog?.cancel();
    final pc = _pc;
    _pc = null;
    try {
      if (ownsStream) {
        for (final t in _local?.getTracks() ?? <MediaStreamTrack>[]) {
          await t.stop();
        }
        await _local?.dispose();
      }
      await pc?.close();
    } catch (_) {}
    _setState(EngineState.closed);
  }

  // ---------- internals ----------

  Future<void> _offer(bool iceRestart) async {
    final pc = _pc;
    if (pc == null) return;
    try {
      final offer = await pc.createOffer({if (iceRestart) 'iceRestart': true});
      await pc.setLocalDescription(offer);
      sendSignal({'type': 'offer', 'sdp': offer.sdp, if (iceRestart) 'restart': true});
    } catch (e) {
      // ignore: avoid_print
      print('[call] offer failed: $e');
    }
  }

  Future<void> _flush() async {
    final queued = List<RTCIceCandidate>.from(_pending);
    _pending.clear();
    for (final c in queued) {
      try {
        await _pc?.addCandidate(c);
      } catch (_) {}
    }
  }

  void _onConnectionState(RTCPeerConnectionState s) {
    switch (s) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _restartTimer?.cancel();
        _setState(EngineState.connected);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _setState(EngineState.reconnecting);
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 2500), restartIce);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        restartIce();
        break;
      default:
        break;
    }
  }

  void _setState(EngineState s) {
    if (_state == s) return;
    _state = s;
    onState(s);
  }
}

/// Recorded calls: sends this side's microphone to the server, which records both voices (see
/// server/src/calls/callRecorder.ts). A separate send-only connection, so it can never disturb the
/// call's own audio. Uses the call's microphone track, so muting is respected.
class RecordingUplink {
  RecordingUplink({required this.iceServers, required this.stream, required this.offer, this.video = false});

  final List<Map<String, dynamic>> iceServers;
  final MediaStream stream;

  /// The call's video is recorded (admin "Record video", or staff turned it on mid-call): send the
  /// camera too (when it's on).
  bool video;
  MediaStreamTrack? _camera;

  /// Sends the offer to the server (call:rec_offer) and returns its answer, or null.
  final Future<String?> Function(String sdp) offer;

  RTCPeerConnection? _pc;
  bool _closed = false;
  int _retries = 0;

  Future<bool> start() async {
    final track = stream.getAudioTracks().isEmpty ? null : stream.getAudioTracks().first;
    if (_closed || track == null) return false;
    try {
      final pc = await createPeerConnection({'iceServers': iceServers, 'sdpSemantics': 'unified-plan'});
      _pc = pc;
      await pc.addTransceiver(
        track: track,
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly, streams: [stream]),
      );
      // Always negotiated so video recording can be turned on mid-call; the camera is only sent
      // while the call's video is recorded
      final camera = video ? _camera : null;
      if (camera != null) {
        await pc.addTransceiver(track: camera, kind: RTCRtpMediaType.RTCRtpMediaTypeVideo, init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly));
      } else {
        await pc.addTransceiver(kind: RTCRtpMediaType.RTCRtpMediaTypeVideo, init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendOnly));
      }
      // One round trip: send the offer with the candidates found within a second (local + STUN)
      // instead of trickling them; waiting for every TURN candidate delayed the start of recording
      final gathered = Completer<void>();
      pc.onIceGatheringState = (state) {
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete && !gathered.isCompleted) gathered.complete();
      };
      await pc.setLocalDescription(await pc.createOffer());
      await gathered.future.timeout(const Duration(seconds: 1), onTimeout: () {});
      final local = await pc.getLocalDescription();
      final answer = await offer(local?.sdp ?? '');
      if (answer == null || _closed) return false;
      await pc.setRemoteDescription(RTCSessionDescription(answer, 'answer'));
      pc.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed && !_closed && _retries < 3) {
          _retries++;
          pc.close();
          Future.delayed(Duration(seconds: _retries), start);
        }
      };
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[call] recording uplink failed: $e');
      return false;
    }
  }

  /// Camera on/off; sent to the recorder only while video is recorded.
  Future<void> setCamera(MediaStreamTrack? track) async {
    _camera = track;
    final pc = _pc;
    if (pc == null) return;
    try {
      for (final t in await pc.getTransceivers()) {
        if (t.sender.track?.kind == 'video' || (t.sender.track == null && t.receiver.track?.kind == 'video')) {
          await t.sender.replaceTrack(video ? track : null);
        }
      }
    } catch (_) {}
  }

  /// Staff turned on video recording mid-call: start sending the camera.
  Future<void> setRecordVideo(bool on) async {
    video = on;
    await setCamera(_camera);
  }

  Future<void> close() async {
    _closed = true;
    final pc = _pc;
    _pc = null;
    try {
      await pc?.close();
    } catch (_) {}
  }
}
