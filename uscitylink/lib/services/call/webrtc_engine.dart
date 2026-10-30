import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// One WebRTC audio connection to the other person on a call — the Flutter twin of
/// web/src/calls/webrtcEngine.ts, with the same rules:
///   * only the CALLER sends offers (first offer after "call:accepted", and ICE restarts);
///     the callee answers, or asks for a restart with {type: 'restart-request'};
///   * ICE candidates that arrive before the remote description are queued.
/// For group calls / recording this is the piece to replace with an SFU client.
enum EngineState { connecting, connected, reconnecting, failed, closed }

class WebRtcEngine {
  WebRtcEngine({
    required this.iceServers,
    required this.isCaller,
    required this.sendSignal,
    required this.onState,
  });

  final List<Map<String, dynamic>> iceServers;
  final bool isCaller;
  final void Function(Map<String, dynamic> data) sendSignal;
  final void Function(EngineState state) onState;

  static const _maxRestarts = 6;

  RTCPeerConnection? _pc;
  MediaStream? _local;
  final List<RTCIceCandidate> _pending = [];
  int _restarts = 0;
  Timer? _restartTimer;
  bool _closed = false;
  EngineState _state = EngineState.connecting;

  int get iceRestarts => _restarts;

  static Future<MediaStream> openMicrophone() => navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
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
    if (isCaller) await _offer(false);
  }

  Future<void> handleSignal(Map<String, dynamic> data) async {
    final pc = _pc;
    if (_closed || pc == null) return;
    try {
      switch (data['type']) {
        case 'offer':
          await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));
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
    final pc = _pc;
    _pc = null;
    try {
      for (final t in _local?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await _local?.dispose();
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
