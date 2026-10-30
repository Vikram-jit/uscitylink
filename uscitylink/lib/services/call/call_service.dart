import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStream, MediaStreamTrack;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/services/call/call_kit.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_tones.dart';
import 'package:uscitylink/services/call/webrtc_engine.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/views/call/call_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Voice calls in the app (driver ↔ dispatch). The server (server/src/calls) decides who rings and
/// when a call ends; this service runs WebRTC, the native call UI (CallKit / full-screen Android
/// call screen) and the in-app call screen.
///
/// Incoming calls can arrive three ways and are de-duplicated by call id:
///   socket "call:incoming" (app open), FCM data push (Android, app closed — call_kit.dart),
///   APNs VoIP push (iOS, shown natively by AppDelegate.swift).
class CallService extends GetxService with WidgetsBindingObserver {
  static CallService get to => Get.isRegistered<CallService>() ? Get.find() : Get.put(CallService(), permanent: true);

  final phase = CallPhase.idle.obs;
  final info = Rxn<CallInfo>();
  final peerName = ''.obs;
  final peerSubtitle = ''.obs;
  final answeredAt = Rxn<DateTime>();
  final muted = false.obs;
  final speaker = false.obs;
  final remoteMuted = false.obs;
  final reconnecting = false.obs;
  final endedText = ''.obs;
  /// Place in the dispatch waiting line (1 = next), while every dispatcher is busy.
  final queuePosition = 0.obs;
  final enabled = true.obs;

  WebRtcEngine? _engine;
  MediaStream? _pendingMic;
  List<Map<String, dynamic>> _iceServers = [];
  final List<Map<String, dynamic>> _pendingSignals = [];
  final Set<String> _accepting = {};
  // Calls answered on the phone's native call screen: its End button means hang up. Every other
  // native event (e.g. CallKit failing, or us dismissing its screen) must not end a call.
  final Set<String> _nativeAccepted = {};
  io.Socket? _boundSocket;
  StreamSubscription? _callkitSub;
  Timer? _endedTimer;
  bool _isCaller = false;

  String? get callId => info.value?.callId;
  bool get busy => phase.value != CallPhase.idle && phase.value != CallPhase.ended;

  // ---------- lifecycle ----------

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _callkitSub = FlutterCallkitIncoming.onEvent.listen(_onCallKitEvent);
    final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
    if (socketService != null) {
      ever<bool>(socketService.isConnected, (connected) {
        if (connected) _bindSocket(socketService.socket);
      });
      if (socketService.isConnected.value) _bindSocket(socketService.socket);
    }
    _afterLaunch();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _callkitSub?.cancel();
    super.onClose();
  }

  bool get _inForeground => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Opened the app while a call is ringing: switch to the in-app incoming screen
    if (state == AppLifecycleState.resumed && phase.value == CallPhase.incoming) {
      _openCallScreen();
      CallTones.ringtone();
    }
  }

  /// Answered from the lock screen while the app was closed: pick the call up now.
  Future<void> _afterLaunch() async {
    await refreshConfig();
    await registerVoipToken();
    if (Platform.isAndroid) {
      try {
        // Full-screen incoming call over the lock screen (Android 14+ asks once)
        if (!await FlutterCallkitIncoming.canUseFullScreenIntent()) {
          await FlutterCallkitIncoming.requestFullIntentPermission();
        }
      } catch (_) {}
    }
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      for (final c in calls) {
        if (c.isAccepted && !busy) unawaited(accept(c.id, fromNative: true));
      }
    } catch (_) {}
  }

  Future<void> refreshConfig() async {
    final res = await _rest('GET', 'calls/config');
    if (res?['data'] is Map) enabled.value = res!['data']['enabled'] != false;
  }

  /// iOS PushKit token so the server can ring this phone when the app is closed.
  Future<void> registerVoipToken() async {
    if (!Platform.isIOS) return;
    try {
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      if (token != null && token.toString().isNotEmpty) await _rest('PUT', 'calls/voip-token', {'token': token});
    } catch (_) {}
  }

  /// Before the saved login is removed: stop ringing this phone for that account.
  Future<void> onLogout() async {
    if (busy) await hangup();
    if (Platform.isIOS) await _rest('PUT', 'calls/voip-token', {'token': null});
  }

  // ---------- outgoing ----------

  /// Staff: pass [driverId]. Driver: leave it empty to call dispatch on [channelId].
  Future<void> startCall({String? driverId, String? channelId, required String name, String subtitle = ''}) async {
    if (busy) {
      _toast('Finish the current call first');
      return;
    }
    if (!enabled.value) {
      _toast('Calling is turned off');
      return;
    }
    final mic = await _openMicrophone();
    if (mic == null) return;
    _reset();
    _isCaller = true;
    _pendingMic = mic;
    phase.value = CallPhase.outgoing;
    peerName.value = name;
    peerSubtitle.value = subtitle;
    _openCallScreen();

    final res = await _emitAck('call:invite', {
      if (driverId != null && driverId.isNotEmpty) 'driverId': driverId,
      if (channelId != null && channelId.isNotEmpty) 'channelId': channelId,
    });
    if (res['ok'] != true) {
      await _releasePendingMic();
      final error = res['error'];
      await _finish(error == 'busy'
          ? '$name is on another call'
          : error == 'unavailable'
              ? 'Nobody is available right now'
              : (res['message'] ?? 'Could not start the call').toString());
      return;
    }
    _iceServers = _ice(res);
    if (res['call'] is Map) info.value = CallInfo.fromJson(Map<String, dynamic>.from(res['call']));
    if (res['queued'] == true) {
      phase.value = CallPhase.queued;
      queuePosition.value = (res['position'] as num?)?.toInt() ?? 1;
    } else {
      CallTones.ringback();
    }
    // Outgoing calls run in the app (no native CallKit call): a CallKit failure must never be
    // able to end them.
  }

  // ---------- incoming ----------

  Future<void> _onIncoming(CallInfo call) async {
    if (call.callId.isEmpty || callId == call.callId) return;
    if (busy) return; // the server already avoids ringing someone who is on a call
    _reset();
    _isCaller = false;
    info.value = call;
    phase.value = CallPhase.incoming;
    peerName.value = CallKit.callerTitle(call);
    peerSubtitle.value = CallKit.callerSubtitle(call);
    if (_inForeground || !CallKit.available) {
      // App open: our own incoming screen with Accept / Decline and a ringtone
      _openCallScreen();
      await CallTones.ringtone();
    } else {
      await CallKit.showIncoming(call);
    }
  }

  static bool isCallPush(Map data) => '${data['type'] ?? ''}'.startsWith('CALL_');

  /// The user tapped a call notification (incoming / missed). If that call is still ringing, show
  /// the incoming screen; otherwise tell them they missed it.
  Future<void> openFromNotification(Map<String, dynamic> data) async {
    final id = '${data['callId'] ?? ''}';
    if (data['type'] != 'CALL_INCOMING' || id.isEmpty) return;
    if (callId == id && phase.value == CallPhase.incoming) {
      _openCallScreen();
      await CallTones.ringtone();
      return;
    }
    if (busy) return;
    final res = await _emitAck('call:status', {'callId': id});
    if (res['live'] == true && res['ringing'] == true && res['call'] is Map) {
      await _onIncoming(CallInfo.fromJson(Map<String, dynamic>.from(res['call'])));
    } else {
      _toast('Missed call from ${data['callerName'] ?? 'dispatch'}');
    }
  }

  /// FCM data while the app is open (fcm_service.dart routes CALL_* here).
  Future<void> onPush(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'CALL_INCOMING':
        await _onIncoming(CallInfo.fromPush(data));
        break;
      case 'CALL_ENDED':
        if (callId == data['callId'] && phase.value == CallPhase.incoming) {
          await CallKit.end('${data['callId']}');
          _reset();
        }
        break;
    }
  }

  Future<void> accept(String id, {bool fromNative = false}) async {
    if (_accepting.contains(id) || (callId == id && phase.value != CallPhase.incoming && phase.value != CallPhase.idle)) {
      return;
    }
    _accepting.add(id);
    await CallTones.stop();
    if (fromNative) {
      _nativeAccepted.add(id);
    } else {
      // Answered in the app: dismiss the native screen if a push also showed it
      await CallKit.end(id);
    }
    try {
      final mic = await _openMicrophone();
      if (mic == null) {
        await declineCall(id);
        return;
      }
      _isCaller = false;
      phase.value = CallPhase.connecting;
      _openCallScreen();
      final res = await _emitAck('call:accept', {'callId': id}, connectFirst: true);
      if (res['ok'] != true) {
        await mic.dispose();
        await CallKit.end(id);
        await _finish((res['message'] ?? 'This call has ended').toString());
        return;
      }
      _iceServers = _ice(res);
      final call = CallInfo.fromJson(Map<String, dynamic>.from(res['call'] ?? {}));
      info.value = call;
      peerName.value = CallKit.callerTitle(call);
      peerSubtitle.value = CallKit.callerSubtitle(call);
      answeredAt.value = DateTime.now();
      await _startEngine(mic, call.callId);
    } finally {
      _accepting.remove(id);
    }
  }

  Future<void> declineCall(String id) async {
    await CallTones.stop();
    final res = await _emitAck('call:decline', {'callId': id}, connectFirst: false);
    if (res['ok'] != true) await _rest('POST', 'calls/$id/decline');
    await CallKit.end(id);
    if (callId == id) _closeRinging();
  }

  /// An incoming call stopped ringing (declined, answered elsewhere, caller hung up).
  void _closeRinging() {
    CallTones.stop();
    _reset();
    if (Get.currentRoute == '/CallView') Get.back();
  }

  // ---------- in call ----------

  Future<void> hangup() async {
    final id = callId;
    if (id == null) {
      await _releasePendingMic();
      return _finish('Call cancelled');
    }
    final res = await _emitAck('call:end', {'callId': id}, connectFirst: false);
    if (res['ok'] != true) await _rest('POST', 'calls/$id/end');
    await CallKit.end(id);
    final talked = answeredAt.value == null ? 0 : DateTime.now().difference(answeredAt.value!).inSeconds;
    await _finish(phase.value == CallPhase.active && talked > 0
        ? 'Call ended · ${formatCallDuration(talked)}'
        : (_isCaller && answeredAt.value == null ? 'Call cancelled' : 'Call ended'));
  }

  void toggleMute() => setMuted(!muted.value);

  void setMuted(bool value) {
    muted.value = value;
    _engine?.setMuted(value);
    final id = callId;
    if (id != null) {
      _boundSocket?.emit('call:media', {'callId': id, 'muted': value});
      FlutterCallkitIncoming.muteCall(id, isMuted: value).catchError((_) {});
    }
  }

  Future<void> toggleSpeaker() async {
    speaker.value = !speaker.value;
    await _engine?.setSpeaker(speaker.value);
  }

  // ---------- socket ----------

  void _bindSocket(io.Socket socket) {
    if (identical(socket, _boundSocket)) return;
    _boundSocket = socket;
    socket.on('call:incoming', (d) => _onIncoming(CallInfo.fromJson(Map<String, dynamic>.from(d))));
    socket.on('call:accepted', (d) => _onAccepted(Map<String, dynamic>.from(d)));
    // Dispatch line: every dispatcher busy → waiting in line; then it rings whoever frees up
    socket.on('call:queued', (d) {
      if (callId != d['callId']) return;
      phase.value = CallPhase.queued;
      queuePosition.value = (d['position'] as num?)?.toInt() ?? queuePosition.value;
      CallTones.stop();
    });
    socket.on('call:ringing', (d) {
      if (callId == d['callId'] && phase.value == CallPhase.queued) {
        phase.value = CallPhase.outgoing;
        queuePosition.value = 0;
        CallTones.ringback();
      }
    });
    socket.on('call:answered_elsewhere', (d) async {
      if (callId != d['callId']) return;
      await CallKit.end(d['callId']);
      _closeRinging();
    });
    socket.on('call:signal', (d) {
      if (callId != d['callId']) return;
      final data = Map<String, dynamic>.from(d['data'] ?? {});
      if (_engine != null) {
        _engine!.handleSignal(data);
      } else {
        _pendingSignals.add(data);
      }
    });
    socket.on('call:media', (d) {
      if (callId == d['callId']) remoteMuted.value = d['muted'] == true;
    });
    socket.on('call:peer_reconnecting', (d) {
      if (callId == d['callId']) reconnecting.value = true;
    });
    socket.on('call:peer_reconnected', (d) {
      if (callId == d['callId']) _engine?.restartIce();
    });
    socket.on('call:resume', (d) {
      // Our socket reconnected mid-call: renegotiate the network path. If the app restarted there
      // is no audio left to resume, so end it cleanly.
      if (_engine != null && callId == d['callId']) {
        _engine!.restartIce();
      } else {
        socket.emit('call:end', {'callId': d['callId']});
      }
    });
    socket.on('call:ended', (d) async {
      if (callId != d['callId']) return;
      await CallKit.end(d['callId']);
      if (phase.value == CallPhase.incoming) {
        _closeRinging();
        return;
      }
      await _releasePendingMic();
      final status = '${d['status']}';
      final seconds = (d['durationSec'] as num?)?.toInt() ?? 0;
      await _finish(status == 'completed' && seconds > 0
          ? 'Call ended · ${formatCallDuration(seconds)}'
          : (callEndedText[status] ?? 'Call ended'));
    });
  }

  Future<void> _onAccepted(Map<String, dynamic> d) async {
    if (callId != d['callId'] || (phase.value != CallPhase.outgoing && phase.value != CallPhase.queued)) return;
    queuePosition.value = 0;
    await CallTones.stop();
    final mic = _pendingMic;
    _pendingMic = null;
    if (mic == null) {
      _boundSocket?.emit('call:end', {'callId': d['callId']});
      return;
    }
    phase.value = CallPhase.connecting;
    answeredAt.value = DateTime.now();
    if (d['by'] is Map) {
      final by = CallPeer.fromJson(Map<String, dynamic>.from(d['by']));
      if (by.role == 'staff') peerSubtitle.value = 'Dispatch · ${by.name}';
    }
    await _startEngine(mic, d['callId']);
  }

  Future<void> _startEngine(MediaStream mic, String id) async {
    final engine = WebRtcEngine(
      iceServers: _iceServers,
      isCaller: _isCaller,
      sendSignal: (data) => _boundSocket?.emit('call:signal', {'callId': id, 'data': data}),
      onState: (s) {
        switch (s) {
          case EngineState.connected:
            phase.value = CallPhase.active;
            reconnecting.value = false;
            FlutterCallkitIncoming.setCallConnected(id).catchError((_) {});
            break;
          case EngineState.reconnecting:
            reconnecting.value = true;
            break;
          case EngineState.failed:
            _toast('The call connection was lost');
            hangup();
            break;
          default:
            break;
        }
      },
    );
    _engine = engine;
    WakelockPlus.enable().catchError((_) {});
    await engine.start(mic);
    await engine.setSpeaker(speaker.value);
    final queued = List<Map<String, dynamic>>.from(_pendingSignals);
    _pendingSignals.clear();
    for (final s in queued) {
      await engine.handleSignal(s);
    }
  }

  // ---------- CallKit / native call screen ----------

  Future<void> _onCallKitEvent(CallEvent? event) async {
    if (event == null) return;
    if (event is CallEventActionCallAccept) {
      await accept(event.callKitParams.id, fromNative: true);
    } else if (event is CallEventActionCallDecline) {
      // Declined on the native ringing screen. Ignore it for a call that isn't ringing here any more
      // (answered in the app, or a native failure reported as a decline).
      final id = event.callKitParams.id;
      final ringingHere = callId == id && phase.value == CallPhase.incoming;
      final notSeenYet = callId == null && !_inForeground; // app woken from closed, call not loaded yet
      if (ringingHere || notSeenYet) await declineCall(id);
    } else if (event is CallEventActionCallEnded) {
      final id = event.callKitParams.id;
      if (_nativeAccepted.contains(id) && callId == id && phase.value != CallPhase.ended && phase.value != CallPhase.idle) {
        await hangup();
      }
    } else if (event is CallEventActionCallToggleMute) {
      if (callId == event.id && muted.value != event.isMuted) setMuted(event.isMuted);
    } else if (event is CallEventActionCallTimeout) {
      if (callId == event.id && phase.value == CallPhase.incoming) _reset();
    } else if (event is CallEventActionDidUpdateDevicePushTokenVoip) {
      await registerVoipToken();
    }
  }

  // ---------- helpers ----------

  void _openCallScreen() {
    if (Get.currentRoute != '/CallView') Get.to(() => const CallView(), routeName: '/CallView');
  }

  Future<MediaStream?> _openMicrophone() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _toast(status.isPermanentlyDenied
          ? 'Allow microphone access for USCityLink in Settings to make calls'
          : 'Microphone access is needed for calls');
      if (status.isPermanentlyDenied) await openAppSettings();
      return null;
    }
    try {
      return await WebRtcEngine.openMicrophone();
    } catch (e) {
      _toast('Could not open the microphone');
      return null;
    }
  }

  Future<void> _releasePendingMic() async {
    final mic = _pendingMic;
    _pendingMic = null;
    try {
      for (final t in mic?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await mic?.dispose();
    } catch (_) {}
  }

  /// Ends locally: saves call quality, closes audio, shows "Call ended" briefly, then closes the screen.
  Future<void> _finish(String text) async {
    await CallTones.stop();
    final engine = _engine;
    final id = callId;
    _engine = null;
    _pendingSignals.clear();
    if (engine != null) {
      final stats = await engine.stats(Platform.operatingSystem);
      await engine.close();
      if (id != null && answeredAt.value != null) unawaited(_rest('POST', 'calls/$id/quality', stats));
    }
    WakelockPlus.disable().catchError((_) {});
    endedText.value = text;
    phase.value = CallPhase.ended;
    reconnecting.value = false;
    _endedTimer?.cancel();
    _endedTimer = Timer(const Duration(milliseconds: 1800), () {
      if (phase.value != CallPhase.ended) return;
      _reset();
      if (Get.currentRoute == '/CallView') Get.back();
    });
  }

  void _reset() {
    _endedTimer?.cancel();
    final id = callId;
    if (id != null) _nativeAccepted.remove(id);
    phase.value = CallPhase.idle;
    info.value = null;
    answeredAt.value = null;
    muted.value = false;
    speaker.value = false;
    remoteMuted.value = false;
    reconnecting.value = false;
    endedText.value = '';
    queuePosition.value = 0;
  }

  List<Map<String, dynamic>> _ice(Map<String, dynamic> res) =>
      (res['iceServers'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  /// Socket.IO request/response. Waits briefly for the socket after a push woke the app.
  Future<Map<String, dynamic>> _emitAck(String event, Map<String, dynamic> data, {bool connectFirst = true}) async {
    final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
    if (socketService == null) return {'ok': false, 'message': 'Not connected'};
    if (!socketService.isConnected.value && connectFirst) {
      unawaited(socketService.connectSocket());
      final until = DateTime.now().add(const Duration(seconds: 10));
      while (!socketService.isConnected.value && DateTime.now().isBefore(until)) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    if (!socketService.isConnected.value) return {'ok': false, 'message': 'No connection to the server'};
    _bindSocket(socketService.socket);
    final completer = Completer<Map<String, dynamic>>();
    socketService.socket.emitWithAck(event, data, ack: (res) {
      if (!completer.isCompleted) completer.complete(res is Map ? Map<String, dynamic>.from(res) : {'ok': false});
    });
    return completer.future.timeout(const Duration(seconds: 10),
        onTimeout: () => {'ok': false, 'message': 'The server did not answer'});
  }

  Future<Map<String, dynamic>?> _rest(String method, String path, [Map<String, dynamic>? body]) async {
    try {
      final token = await UserPreferenceController().getToken();
      if (token == null || token.toString().isEmpty) return null;
      final uri = Uri.parse('${Constant.url}/$path');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      final Future<http.Response> request = switch (method) {
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        'POST' => http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
        _ => http.get(uri, headers: headers),
      };
      final res = await request.timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(res.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (e) {
      debugPrint('[call] $method $path failed: $e');
      return null;
    }
  }

  void _toast(String message) {
    if (Get.context == null) return;
    Get.snackbar('Call', message, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
  }
}
