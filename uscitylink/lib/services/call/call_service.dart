import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper, MediaStream, MediaStreamTrack;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
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
/// Group calls (staff add staff): one WebRTC connection per other person, sharing the microphone.
/// Whoever joins sends the offers to everyone already on the call; signals carry `to` and arrive
/// with `from`. A 1-to-1 call is the same with one connection.
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
  /// This call is recorded (shown on the call screen; both sides hear a beep when it connects).
  final recording = false.obs;

  /// Everyone on the call except me (more than one = group call), and people asked to join.
  final members = <CallPeer>[].obs;
  final pending = <CallPeer>[].obs;
  final mutedIds = <String>{}.obs;
  bool get isGroup => members.length > 1;

  /// After my call wasn't answered: leave a voice message in the chat instead (like iPhone voicemail).
  final voicemail = VoicemailState.none.obs;
  final voicemailSeconds = 0.obs;
  static const voicemailMaxSeconds = 120;
  ({String? channelId, String? driverId})? _voicemailTo;
  FlutterSoundRecorder? _vmRecorder;
  String? _vmPath;
  Timer? _vmTimer;

  // ---------- video ----------
  /// The call started as a video call. Any call can turn cameras on/off.
  final isVideoCall = false.obs;
  final cameraOn = false.obs;
  final frontCamera = true.obs;
  /// People on the call whose camera is on, and everyone's audio + video by user id.
  final remoteCamera = <String>{}.obs;
  final remoteStreams = <String, MediaStream>{}.obs;
  /// My camera, for the self-view.
  final localVideo = Rxn<MediaStream>();
  MediaStream? _cameraStream;
  bool _resumeCameraOnReturn = false;

  /// Video is showing (anyone's camera on, or a video call).
  bool get videoActive => isVideoCall.value || cameraOn.value || remoteCamera.isNotEmpty;

  /// Drivers must show their camera on video calls (dispatch needs to see them); staff may not have one.
  bool get cameraRequired => !isStaffUser.value && isVideoCall.value;

  /// Signed in as staff (not a driver): can add people to a call and transfer it.
  final isStaffUser = false.obs;
  static const maxParticipants = 6;

  /// Staff: drivers on a call right now (driver id → everyone on that call), for "On call" marks.
  final onCallDrivers = <String, List<CallPeer>>{}.obs;

  /// One connection per other person on the call, by their user id.
  final Map<String, WebRtcEngine> _engines = {};
  MediaStream? _mic;
  RecordingUplink? _uplink;
  MediaStream? _pendingMic;
  List<Map<String, dynamic>> _iceServers = [];
  /// Signals from someone whose connection doesn't exist yet, by sender.
  final Map<String, List<Map<String, dynamic>>> _pendingSignals = {};
  String? _myIdCache;
  final Set<String> _accepting = {};
  // Calls answered on the phone's native call screen: its End button means hang up. Every other
  // native event (e.g. CallKit failing, or us dismissing its screen) must not end a call.
  final Set<String> _nativeAccepted = {};
  // Calls whose native screen the app closed itself (ended elsewhere, answered in the app, …). iOS
  // reports that as a "decline"; it must never be sent to the server as the user declining.
  final Set<String> _selfEnded = {};
  io.Socket? _boundSocket;
  StreamSubscription? _callkitSub;
  Timer? _endedTimer;
  bool _isCaller = false;

  String? get callId => info.value?.callId;
  bool get busy => phase.value != CallPhase.idle && phase.value != CallPhase.ended;

  /// True while a call is ringing or connected. Screens that drop the socket when the app goes to
  /// the background must skip that during a call: the call's signalling runs on that socket.
  static bool get inCall => Get.isRegistered<CallService>() && Get.find<CallService>().busy;

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
    // The camera can't run in the background (iOS/Android rules): off when leaving, back on return
    if (state == AppLifecycleState.paused && cameraOn.value && busy) {
      _resumeCameraOnReturn = true;
      setCamera(false);
    } else if (state == AppLifecycleState.resumed && busy && phase.value != CallPhase.incoming) {
      if (_resumeCameraOnReturn || (cameraRequired && !cameraOn.value)) {
        _resumeCameraOnReturn = false;
        setCamera(true);
      }
    }
    final call = info.value;
    if (phase.value != CallPhase.incoming || call == null) return;
    if (state == AppLifecycleState.paused) {
      // Minimised while our own incoming screen was ringing: show the phone's call screen instead
      // (CallKit / Android full-screen call), like an incoming WhatsApp call
      CallTones.stop();
      CallKit.showIncoming(call);
    } else if (state == AppLifecycleState.resumed) {
      // Back in the app while it rings: show the in-app incoming screen. If the native screen is
      // still ringing, let it ring rather than playing a second ringtone.
      _openCallScreen();
      CallKit.isShowing(call.callId).then((native) {
        if (!native && phase.value == CallPhase.incoming) CallTones.ringtone();
      });
    }
  }

  /// Answered from the lock screen while the app was closed: pick the call up now.
  Future<void> _afterLaunch() async {
    final role = '${await UserPreferenceController().getRole() ?? ''}';
    isStaffUser.value = role.isNotEmpty && role != 'driver';
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
    // Opened by tapping one of our calls in the Phone app's Recents (app wasn't running)
    unawaited(_callBackFromRecents());
  }

  // ---------- calling back from the Phone app's Recents (iOS) ----------

  static const _recentsTargetsKey = 'recents_call_targets';

  /// Recents only gives back the text shown for a call ("Dispatch · Navjot", "Driver · US CITYLINK").
  /// Remember who that text stands for, so tapping it can call them back.
  Future<void> _rememberForRecents(CallInfo call) async {
    if (!Platform.isIOS || call.from.id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final targets = Map<String, dynamic>.from(jsonDecode(prefs.getString(_recentsTargetsKey) ?? '{}') as Map);
      targets.remove(CallKit.callerSubtitle(call)); // re-insert last = newest
      targets[CallKit.callerSubtitle(call)] = {
        'id': call.from.id,
        'name': call.from.name,
        'role': call.from.role,
        'channelId': call.channelId,
        'channelName': call.channelName,
      };
      while (targets.length > 50) {
        targets.remove(targets.keys.first);
      }
      await prefs.setString(_recentsTargetsKey, jsonEncode(targets));
    } catch (_) {}
  }

  bool _recentsBusy = false;

  /// Place the call the user tapped in Recents: a driver calls the dispatch line for that channel,
  /// staff call that driver back.
  Future<void> _callBackFromRecents() async {
    if (!Platform.isIOS || _recentsBusy) return;
    _recentsBusy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // written natively by AppDelegate.swift
      final handle = prefs.getString('recents_call_handle');
      final at = prefs.getInt('recents_call_at') ?? 0;
      await prefs.remove('recents_call_handle');
      await prefs.remove('recents_call_at');
      if (handle == null || DateTime.now().millisecondsSinceEpoch - at > 60000) return;
      if (busy) return;

      final targets = Map<String, dynamic>.from(jsonDecode(prefs.getString(_recentsTargetsKey) ?? '{}') as Map);
      final t = targets[handle] is Map ? Map<String, dynamic>.from(targets[handle]) : null;
      final myRole = '${await UserPreferenceController().getRole() ?? ''}';

      // Let the app finish opening (login check, dashboard) before showing the call screen
      await _waitUntilReady();
      if (busy) return;
      if (t != null && t['role'] == 'driver') {
        await startCall(driverId: '${t['id']}', name: '${t['name']}', subtitle: 'Driver · ${t['channelName'] ?? ''}');
      } else if (myRole == 'driver') {
        await startCall(
          channelId: t?['channelId'] as String?,
          name: (t?['channelName'] as String?)?.isNotEmpty == true ? t!['channelName'] : 'Dispatch',
          subtitle: 'Dispatch',
        );
      } else {
        _toast("Open the driver's chat to call them");
      }
    } catch (e) {
      debugPrint('[call] calling back from Recents failed: $e');
    } finally {
      _recentsBusy = false;
    }
  }

  Future<void> _waitUntilReady() async {
    final until = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(until)) {
      final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
      final route = Get.currentRoute;
      if (Get.context != null && socketService?.isConnected.value == true && route.isNotEmpty && route != '/') break;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Future.delayed(const Duration(milliseconds: 600));
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
  Future<void> startCall({String? driverId, String? channelId, required String name, String subtitle = '', bool video = false}) async {
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
    _voicemailTo = (channelId: channelId, driverId: driverId);
    _pendingMic = mic;
    phase.value = CallPhase.outgoing;
    peerName.value = name;
    peerSubtitle.value = subtitle;
    _openCallScreen();

    isVideoCall.value = video;
    if (video) {
      final on = await setCamera(true, announce: false);
      if (!on && cameraRequired) {
        // Drivers must show their camera on a video call
        await _releasePendingMic();
        _reset();
        if (Get.currentRoute == '/CallView') Get.back();
        return;
      }
      await Helper.setSpeakerphoneOn(true).catchError((_) {});
      speaker.value = true;
    }
    final res = await _emitAck('call:invite', {
      'group': true, // this app version can do group calls (older ones can't)
      'video': true, // …and video
      'type': video ? 'video' : 'audio',
      if (driverId != null && driverId.isNotEmpty) 'driverId': driverId,
      if (channelId != null && channelId.isNotEmpty) 'channelId': channelId,
    });
    if (res['ok'] != true) {
      await _releasePendingMic();
      final error = res['error'];
      await _finish(
          error == 'busy'
              ? '$name is on another call'
              : error == 'unavailable'
                  ? 'Nobody is available right now'
                  : (res['message'] ?? 'Could not start the call').toString(),
          offerVoicemail: error == 'busy' || error == 'unavailable');
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
    unawaited(_rememberForRecents(call));
    if (call.invitedBy != null) {
      // A request to join someone else's call (group call)
      peerName.value = call.invitedBy!.name;
      final on = call.members.where((m) => m.id != call.invitedBy!.id).map((m) => m.name).join(', ');
      if (call.transfer) {
        peerSubtitle.value = on.isEmpty ? 'Is transferring a call to you' : 'Is transferring a call to you · $on';
      } else {
        peerSubtitle.value = on.isEmpty ? 'Asks you to join a call' : 'Asks you to join a call with $on';
      }
    } else {
      peerName.value = CallKit.callerTitle(call);
      peerSubtitle.value = CallKit.callerSubtitle(call);
    }
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
          await _endNative('${data['callId']}');
          _reset();
        }
        break;
    }
  }

  Future<void> accept(String id, {bool fromNative = false, bool? video}) async {
    if (_accepting.contains(id) || (callId == id && phase.value != CallPhase.incoming && phase.value != CallPhase.idle)) {
      return;
    }
    _accepting.add(id);
    await CallTones.stop();
    if (fromNative) {
      _nativeAccepted.add(id);
    } else {
      // Answered in the app: dismiss the native screen if a push also showed it
      await _endNative(id);
    }
    try {
      final mic = await _openMicrophone();
      if (mic == null) {
        await declineCall(id);
        return;
      }
      _isCaller = false;
      // Video call: drivers always answer with their camera (staff choose Video / Voice). Answered
      // from the lock screen the camera can't start yet — it starts when the app opens.
      final videoCall = (info.value?.type ?? '') == 'video';
      isVideoCall.value = videoCall;
      final wantCamera = video ?? (videoCall && !isStaffUser.value);
      if (wantCamera) {
        if (_inForeground) {
          await setCamera(true, announce: false);
        } else {
          _resumeCameraOnReturn = true;
        }
        await Helper.setSpeakerphoneOn(true).catchError((_) {});
        speaker.value = true;
      }
      phase.value = CallPhase.connecting;
      _openCallScreen();
      final res = await _emitAck(
          'call:accept', {'callId': id, 'group': true, 'videoCapable': true, 'camera': cameraOn.value},
          connectFirst: true);
      if (res['ok'] != true) {
        await mic.dispose();
        await _endNative(id);
        await _finish((res['message'] ?? 'This call has ended').toString());
        return;
      }
      _iceServers = _ice(res);
      final call = CallInfo.fromJson(Map<String, dynamic>.from(res['call'] ?? {}));
      info.value = call;
      answeredAt.value = DateTime.now();
      final me = await _myId();
      final others = call.members.where((m) => m.id != me).toList();
      members.assignAll(others.isEmpty ? [call.from] : others);
      remoteCamera.assignAll(call.camera.where((id) => id != me));
      pending.assignAll(call.pending.where((m) => m.id != me));
      // Answering a call: the caller sends the offer. Joining a group call: I offer to everyone on it.
      final joining = call.answeredBy != null && call.answeredBy!.id != me;
      if (joining) {
        peerName.value = 'Group call';
        peerSubtitle.value = members.map((m) => m.name).join(', ');
      } else {
        peerName.value = CallKit.callerTitle(call);
        peerSubtitle.value = CallKit.callerSubtitle(call);
      }
      await _startMedia(mic, call.callId, members.map((m) => m.id).toList(), isCaller: joining);
    } finally {
      _accepting.remove(id);
    }
  }

  Future<void> declineCall(String id) async {
    debugPrint('[call] declining $id');
    await CallTones.stop();
    final res = await _emitAck('call:decline', {'callId': id}, connectFirst: false);
    if (res['ok'] != true) await _rest('POST', 'calls/$id/decline');
    await _endNative(id);
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
    await _endNative(id);
    final talked = answeredAt.value == null ? 0 : DateTime.now().difference(answeredAt.value!).inSeconds;
    await _finish(phase.value == CallPhase.active && talked > 0
        ? 'Call ended · ${formatCallDuration(talked)}'
        : (_isCaller && answeredAt.value == null ? 'Call cancelled' : 'Call ended'));
  }

  void toggleMute() => setMuted(!muted.value);

  void setMuted(bool value) {
    muted.value = value;
    for (final t in _mic?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      t.enabled = !value;
    }
    final id = callId;
    if (id != null) {
      _boundSocket?.emit('call:media', {'callId': id, 'muted': value});
      if (_nativeAccepted.contains(id)) FlutterCallkitIncoming.muteCall(id, isMuted: value).catchError((_) {});
    }
  }

  Future<void> toggleSpeaker() async {
    speaker.value = !speaker.value;
    await Helper.setSpeakerphoneOn(speaker.value).catchError((_) {});
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
      await _endNative(d['callId']);
      _closeRinging();
    });
    socket.on('call:signal', (d) {
      if (callId != d['callId']) return;
      final data = Map<String, dynamic>.from(d['data'] ?? {});
      // Older servers don't say who sent it: on a 1-to-1 call it's the only other person
      final from = '${d['from'] ?? (_engines.keys.isNotEmpty ? _engines.keys.first : members.isNotEmpty ? members.first.id : '')}';
      final engine = _engines[from];
      if (engine != null) {
        engine.handleSignal(data);
      } else {
        (_pendingSignals[from] ??= []).add(data);
      }
    });
    socket.on('call:media', (d) {
      if (callId != d['callId']) return;
      final from = '${d['from'] ?? (members.isNotEmpty ? members.first.id : '')}';
      if (d['muted'] == true) {
        mutedIds.add(from);
      } else {
        mutedIds.remove(from);
      }
      remoteMuted.value = mutedIds.isNotEmpty;
      if (d['video'] == true) {
        remoteCamera.add(from);
      } else if (d['video'] == false) {
        remoteCamera.remove(from);
      }
    });
    socket.on('call:peer_reconnecting', (d) {
      if (callId == d['callId']) reconnecting.value = true;
    });
    socket.on('call:peer_reconnected', (d) {
      if (callId != d['callId']) return;
      final engine = _engines['${d['from'] ?? ''}'];
      if (engine != null) {
        engine.restartIce();
      } else {
        for (final e in _engines.values) {
          e.restartIce();
        }
      }
    });
    // Transfer I started: they picked up (call:ended follows for me), or didn't
    socket.on('call:transferred', (d) {
      if (callId == d['callId'] && d['to'] is Map) _toast('Call transferred to ${d['to']['name'] ?? 'them'}');
    });
    socket.on('call:transfer_failed', (d) {
      if (callId != d['callId']) return;
      final who = d['person'] is Map ? '${d['person']['name']}' : 'They';
      _toast("$who ${d['reason'] == 'declined' ? 'declined' : "didn't answer"} — you're still on the call");
    });
    // Staff: who is on a call across the company (sent on connect and on every change)
    socket.on('calls:on_call', (d) => _applyOnCall(d is Map ? d['calls'] : null));
    socket.emitWithAck('calls:on_call_get', {}, ack: (res) {
      if (res is Map && res['ok'] == true) _applyOnCall(res['calls']);
    });
    // Group call: someone joined (they send me the offer) or left; who is on it / being asked
    socket.on('call:member_joined', (d) {
      if (callId != d['callId'] || d['person'] is! Map) return;
      final person = CallPeer.fromJson(Map<String, dynamic>.from(d['person']));
      _connectTo(person.id, callId!, isCaller: false);
      _toast('${person.name} joined the call');
    });
    socket.on('call:member_left', (d) {
      if (callId != d['callId'] || d['person'] is! Map) return;
      final person = CallPeer.fromJson(Map<String, dynamic>.from(d['person']));
      _closePeer(person.id);
      _toast('${person.name} left the call');
    });
    socket.on('call:participants', (d) async {
      if (callId != d['callId']) return;
      final me = await _myId();
      members.assignAll(CallInfo.peerList(d['members']).where((m) => m.id != me));
      pending.assignAll(CallInfo.peerList(d['pending']).where((m) => m.id != me));
      if (d['camera'] is Map) {
        remoteCamera.assignAll(Map<String, dynamic>.from(d['camera']).entries.where((e) => e.value == true && e.key != me).map((e) => e.key));
      }
      for (final e in _engines.values) {
        _applyVideoLimit(e);
      }
      if (isGroup) {
        peerName.value = 'Group call';
        peerSubtitle.value = members.map((m) => m.name).join(', ');
      }
    });
    socket.on('call:resume', (d) {
      // Our socket reconnected mid-call: renegotiate the network path. If the app restarted there
      // is no audio left to resume, so end it cleanly.
      if (_engines.isNotEmpty && callId == d['callId']) {
        for (final e in _engines.values) {
          e.restartIce();
        }
      } else {
        socket.emit('call:end', {'callId': d['callId']});
      }
    });
    socket.on('call:ended', (d) async {
      if (callId != d['callId']) return;
      await _endNative(d['callId']);
      if (phase.value == CallPhase.incoming) {
        _closeRinging();
        return;
      }
      await _releasePendingMic();
      final status = '${d['status']}';
      final seconds = (d['durationSec'] as num?)?.toInt() ?? 0;
      // My call wasn't answered (nobody picked up, declined, busy): offer a voice message instead
      final unanswered = _isCaller && answeredAt.value == null && const ['missed', 'declined', 'busy'].contains(status);
      await _finish(
          d['reason'] == 'transferred'
              ? 'Call transferred'
              : status == 'completed' && seconds > 0
                  ? 'Call ended · ${formatCallDuration(seconds)}'
                  : (callEndedText[status] ?? 'Call ended'),
          offerVoicemail: unanswered);
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
    if (d['by'] is! Map) {
      _boundSocket?.emit('call:end', {'callId': d['callId']});
      return;
    }
    final by = CallPeer.fromJson(Map<String, dynamic>.from(d['by']));
    if (by.role == 'staff') peerSubtitle.value = 'Dispatch · ${by.name}';
    members.assignAll([by]);
    if (d['camera'] is Map && d['camera'][by.id] == true) remoteCamera.add(by.id);
    await _startMedia(mic, d['callId'], [by.id], isCaller: true);
  }

  /// The call was answered: keep the microphone, start recording, connect to [peers].
  Future<void> _startMedia(MediaStream mic, String id, List<String> peers, {required bool isCaller}) async {
    _mic = mic;
    // Android: from the moment the call is answered, keep it (and the microphone) alive in the
    // background with the ongoing-call notification — even while it's still connecting
    if (Platform.isAndroid && !_nativeAccepted.contains(id)) {
      _nativeAccepted.add(id); // its "Hang up" ends the call (see CallEventActionCallEnded)
      unawaited(CallKit.startOngoing(callId: id, title: peerName.value, subtitle: peerSubtitle.value, video: isVideoCall.value));
    }
    WakelockPlus.enable().catchError((_) {});
    _startRecording(id);
    for (final peer in peers) {
      await _connectTo(peer, id, isCaller: isCaller);
    }
    await Helper.setSpeakerphoneOn(speaker.value).catchError((_) {});
  }

  /// The connection to one other person on the call (the microphone is shared by all of them).
  Future<void> _connectTo(String peerId, String id, {required bool isCaller}) async {
    final mic = _mic;
    if (mic == null || _engines.containsKey(peerId)) return;
    final engine = WebRtcEngine(
      iceServers: _iceServers,
      isCaller: isCaller,
      ownsStream: false,
      onRemoteStream: (stream) => remoteStreams[peerId] = stream,
      sendSignal: (data) => _boundSocket?.emit('call:signal', {'callId': id, 'data': data, 'to': peerId}),
      onState: (s) {
        switch (s) {
          case EngineState.connected:
            if (_uplink != null && !recording.value) {
              recording.value = true;
              CallTones.recordingBeep();
            }
            phase.value = CallPhase.active;
            reconnecting.value = false;
            if (_nativeAccepted.contains(id)) FlutterCallkitIncoming.setCallConnected(id).catchError((_) {});
            break;
          case EngineState.reconnecting:
            reconnecting.value = true;
            break;
          case EngineState.failed:
            if (_engines.length <= 1) {
              _toast('The call connection was lost');
              hangup();
            } else {
              // Group call: only the link to this person broke; the server drops them if they're gone
              _closePeer(peerId);
            }
            break;
          default:
            break;
        }
      },
    );
    _engines[peerId] = engine;
    await engine.start(mic);
    await _applyVideoLimit(engine);
    final camera = _cameraTrack;
    if (camera != null) await engine.setCamera(camera);
    final queued = _pendingSignals.remove(peerId) ?? [];
    for (final s in queued) {
      await engine.handleSignal(s);
    }
  }

  void _closePeer(String peerId) {
    _engines.remove(peerId)?.close();
    _pendingSignals.remove(peerId);
    mutedIds.remove(peerId);
    remoteCamera.remove(peerId);
    remoteStreams.remove(peerId);
  }

  MediaStreamTrack? get _cameraTrack {
    final tracks = _cameraStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    return tracks.isEmpty ? null : tracks.first;
  }

  /// Everyone sends video to everyone: lighter once 3+ are on the call.
  Future<void> _applyVideoLimit(WebRtcEngine engine) => members.length + 1 >= 3
      ? engine.setVideoLimit(maxBitrate: 200000, maxFramerate: 12, scale: 2)
      : engine.setVideoLimit(maxBitrate: 500000, maxFramerate: 15, scale: 1);

  /// Camera on/off during the call. Returns whether it's on. [announce] tells the others.
  Future<bool> setCamera(bool on, {bool announce = true}) async {
    if (on == cameraOn.value && (on == (_cameraStream != null))) return on;
    if (on) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _toast(cameraRequired
            ? 'Allow the camera for USCityLink — it is needed for video calls'
            : 'Allow the camera for USCityLink to turn video on');
        if (status.isPermanentlyDenied) await openAppSettings();
        return false;
      }
      try {
        final stream = await WebRtcEngine.openCamera(front: frontCamera.value);
        _cameraStream = stream;
      } catch (e) {
        debugPrint('[call] camera failed: $e');
        _toast('Could not turn the camera on');
        return false;
      }
    } else {
      final stream = _cameraStream;
      _cameraStream = null;
      try {
        for (final t in stream?.getTracks() ?? <MediaStreamTrack>[]) {
          await t.stop();
        }
        await stream?.dispose();
      } catch (_) {}
    }
    final track = _cameraTrack;
    for (final e in _engines.values) {
      await e.setCamera(track);
    }
    await _uplink?.setCamera(track);
    localVideo.value = _cameraStream;
    cameraOn.value = on;
    final id = callId;
    if (announce && id != null) _boundSocket?.emit('call:media', {'callId': id, 'video': on});
    return on;
  }

  Future<void> toggleCamera() => setCamera(!cameraOn.value);

  Future<void> flipCamera() async {
    final track = _cameraTrack;
    if (track == null) return;
    try {
      await Helper.switchCamera(track);
      frontCamera.value = !frontCamera.value;
    } catch (_) {}
  }

  void _applyOnCall(dynamic calls) {
    final map = <String, List<CallPeer>>{};
    for (final c in (calls is List ? calls : const [])) {
      if (c is Map && c['driverId'] != null) map['${c['driverId']}'] = CallInfo.peerList(c['members']);
    }
    onCallDrivers.assignAll(map);
  }

  // ---------- staff: add someone / transfer (same as the dashboard's call bar) ----------

  /// Staff who are online and could join (busy ones flagged).
  Future<List<({String id, String name, bool busy})>> availableStaff() async {
    final res = await _rest('GET', 'calls/available-staff');
    final list = res?['data'] is List ? res!['data'] as List : const [];
    final onCall = {...members.map((m) => m.id), ...pending.map((p) => p.id)};
    return list
        .whereType<Map>()
        .map((m) => (id: '${m['id']}', name: '${m['name'] ?? 'Staff'}', busy: m['busy'] == true))
        .where((s) => !onCall.contains(s.id))
        .toList();
  }

  /// Ask a staff member to join the call, or ([transfer]) hand the call to them — I leave once they
  /// pick up and the driver stays connected.
  Future<void> addPerson(CallPeer person, {bool transfer = false}) async {
    final id = callId;
    if (id == null) return;
    final res = await _emitAck(transfer ? 'call:transfer' : 'call:add', {'callId': id, 'userId': person.id}, connectFirst: false);
    if (res['ok'] != true) {
      _toast('${res['message'] ?? (transfer ? 'Could not transfer the call' : 'Could not add them')}');
      return;
    }
    _toast(transfer ? "Transferring to ${person.name}… you'll leave when they pick up" : 'Calling ${person.name} to join…');
  }

  void cancelAdd(String userId) {
    final id = callId;
    if (id != null) _boundSocket?.emit('call:add_cancel', {'callId': id, 'userId': userId});
  }

  /// Close the phone's call screen for [id] because the app decided so (not the user).
  Future<void> _endNative(String id) {
    if (id.isNotEmpty) _selfEnded.add(id.toLowerCase());
    return CallKit.end(id);
  }

  /// This user's profile id — the same id the server reads from the login token.
  Future<String> _myId() async {
    if (_myIdCache != null) return _myIdCache!;
    try {
      final token = '${await UserPreferenceController().getToken() ?? ''}';
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))));
      _myIdCache = '${payload['id'] ?? ''}';
    } catch (_) {
      _myIdCache = '';
    }
    return _myIdCache!;
  }

  /// Recorded call: send this side's microphone to the server as soon as the call is answered, in
  /// parallel with the call connecting (waiting for "connected" lost the first seconds of a call).
  /// The beep and "Recorded" badge come when the call connects.
  void _startRecording(String id) {
    final stream = _mic;
    if (info.value?.recording != true || _uplink != null || stream == null) return;
    final uplink = RecordingUplink(
      iceServers: _iceServers,
      stream: stream,
      video: info.value?.recordVideo == true,
      offer: (sdp) async {
        final res = await _emitAck('call:rec_offer', {'callId': id, 'sdp': sdp}, connectFirst: false);
        return res['ok'] == true ? '${res['sdp']}' : null;
      },
    );
    _uplink = uplink;
    uplink.setCamera(_cameraTrack).then((_) => uplink.start());
  }

  // ---------- CallKit / native call screen ----------

  Future<void> _onCallKitEvent(CallEvent? event) async {
    if (event == null) return;
    if (event is CallEventActionCallIncoming) {
      await _onNativeIncoming(event.callKitParams);
    } else if (event is CallEventActionCallAccept) {
      await accept(event.callKitParams.id, fromNative: true);
    } else if (event is CallEventActionCallDecline) {
      // Declined on the native ringing screen. Ignore it for a call that isn't ringing here any more
      // (answered in the app, or a native failure reported as a decline).
      final id = event.callKitParams.id;
      if (_accepting.contains(id)) return; // we closed the native screen because it was answered in the app
      if (_selfEnded.contains(id.toLowerCase())) {
        debugPrint('[call] native decline for $id ignored: the app closed that screen itself');
        return;
      }
      final ringingHere = callId == id && phase.value == CallPhase.incoming;
      final notSeenYet = callId == null && !_inForeground; // app woken from closed, call not loaded yet
      debugPrint('[call] native decline for $id (ringingHere=$ringingHere, notSeenYet=$notSeenYet)');
      if (ringingHere || notSeenYet) await declineCall(id);
    } else if (event is CallEventActionCallEnded) {
      final id = event.callKitParams.id;
      if (_selfEnded.contains(id.toLowerCase())) return;
      if (_nativeAccepted.contains(id) && callId == id && phase.value != CallPhase.ended && phase.value != CallPhase.idle) {
        await hangup();
      }
    } else if (event is CallEventActionCallToggleMute) {
      if (callId == event.id && muted.value != event.isMuted) setMuted(event.isMuted);
    } else if (event is CallEventActionCallTimeout) {
      if (callId == event.id && phase.value == CallPhase.incoming) _reset();
    } else if (event is CallEventActionDidUpdateDevicePushTokenVoip) {
      await registerVoipToken();
    } else if (event is CallEventActionCallCustom && event.body['action'] == 'recents_call') {
      // Tapped one of our calls in the Phone app's Recents (AppDelegate.swift) while running
      await _callBackFromRecents();
    }
  }

  /// iOS showed a call from a VoIP push (AppDelegate.swift), possibly with the app closed. Track it
  /// and connect the socket, so a caller who hangs up — or a dispatcher answering elsewhere — stops
  /// the phone ringing right away instead of after the ring timeout.
  Future<void> _onNativeIncoming(CallKitParams params) async {
    final extra = Map<String, dynamic>.from(params.extra ?? {});
    final id = '${extra['callId'] ?? params.id ?? ''}';
    if (id.isEmpty || callId == id || busy) return;
    _reset();
    _isCaller = false;
    info.value = CallInfo.fromPush({...extra, 'callId': id});
    phase.value = CallPhase.incoming;
    unawaited(_rememberForRecents(info.value!));
    peerName.value = CallKit.callerTitle(info.value!);
    peerSubtitle.value = CallKit.callerSubtitle(info.value!);
    // Connects the socket if needed, then checks the call wasn't cancelled before we connected
    final res = await _emitAck('call:status', {'callId': id});
    if (res['ok'] == false && res['live'] == null) return; // no connection: CallKit's own timeout ends it
    if (callId == id && phase.value == CallPhase.incoming && (res['live'] != true || res['ringing'] != true)) {
      await _endNative(id);
      _reset();
    }
  }

  // ---------- helpers ----------

  /// Back to the call screen (e.g. from the dashboard's "On a call" card).
  void openCallScreen() => _openCallScreen();

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
  Future<void> _finish(String text, {bool offerVoicemail = false}) async {
    await CallTones.stop();
    final engines = Map<String, WebRtcEngine>.from(_engines);
    final id = callId;
    _engines.clear();
    _pendingSignals.clear();
    final uplink = _uplink;
    _uplink = null;
    await uplink?.close();
    if (engines.isNotEmpty) {
      final stats = await engines.values.first.stats(Platform.operatingSystem);
      for (final e in engines.values) {
        await e.close();
      }
      if (id != null && answeredAt.value != null) unawaited(_rest('POST', 'calls/$id/quality', stats));
    }
    final mic = _mic;
    _mic = null;
    try {
      for (final t in mic?.getTracks() ?? <MediaStreamTrack>[]) {
        await t.stop();
      }
      await mic?.dispose();
    } catch (_) {}
    if (_cameraStream != null) await setCamera(false, announce: false);
    WakelockPlus.disable().catchError((_) {});
    endedText.value = text;
    phase.value = CallPhase.ended;
    reconnecting.value = false;
    _endedTimer?.cancel();
    // Unanswered: keep the screen up with "Leave a voice message" (closes by itself if not used)
    final offer = offerVoicemail && _voicemailTo != null;
    if (offer) {
      voicemail.value = VoicemailState.offered;
      // Like a phone's voicemail: "leave a message after the tone", beep, and it records by itself
      unawaited(_autoStartVoicemail());
    }
    _endedTimer = Timer(Duration(milliseconds: offer ? 30000 : 1800), () {
      if (phase.value != CallPhase.ended || voicemail.value == VoicemailState.recording) return;
      if (voicemail.value == VoicemailState.sending) return;
      closeEndedScreen();
    });
  }

  /// Close the "call ended" screen (and anything voicemail left open).
  void closeEndedScreen() {
    _stopVoicemailRecorder(deleteFile: true);
    _reset();
    if (Get.currentRoute == '/CallView') Get.back();
  }

  // ---------- voicemail (my call wasn't answered) ----------

  Future<void> _autoStartVoicemail() async {
    await Future.delayed(const Duration(milliseconds: 1200)); // read "Nobody is available…" first
    if (phase.value != CallPhase.ended || voicemail.value != VoicemailState.offered) return;
    await CallTones.recordingBeep();
    if (phase.value != CallPhase.ended || voicemail.value != VoicemailState.offered) return;
    await startVoicemail();
  }

  Future<void> startVoicemail() async {
    if (voicemail.value != VoicemailState.offered) return;
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _toast('Microphone access is needed to record a voice message');
      return;
    }
    _endedTimer?.cancel();
    try {
      final recorder = FlutterSoundRecorder();
      await recorder.openRecorder();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voicemail_${DateTime.now().millisecondsSinceEpoch}.aac';
      await recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
      _vmRecorder = recorder;
      _vmPath = path;
      voicemailSeconds.value = 0;
      voicemail.value = VoicemailState.recording;
      _vmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        voicemailSeconds.value++;
        if (voicemailSeconds.value >= voicemailMaxSeconds) sendVoicemail();
      });
    } catch (e) {
      debugPrint('[call] voicemail recording failed: $e');
      _toast('Could not start recording');
    }
  }

  Future<void> _stopVoicemailRecorder({bool deleteFile = false}) async {
    _vmTimer?.cancel();
    _vmTimer = null;
    final recorder = _vmRecorder;
    _vmRecorder = null;
    try {
      if (recorder?.isRecording == true) await recorder!.stopRecorder();
      await recorder?.closeRecorder();
    } catch (_) {}
    if (deleteFile && _vmPath != null) {
      try {
        await File(_vmPath!).delete();
      } catch (_) {}
      _vmPath = null;
    }
  }

  /// Stop recording and send it into the chat as a voice message.
  Future<void> sendVoicemail() async {
    if (voicemail.value != VoicemailState.recording) return;
    await _stopVoicemailRecorder();
    final path = _vmPath;
    if (path == null || voicemailSeconds.value < 1) {
      _toast('The voice message is too short');
      voicemail.value = VoicemailState.offered;
      return;
    }
    voicemail.value = VoicemailState.sending;
    final sent = await _deliverVoicemail(File(path));
    if (!sent) {
      voicemail.value = VoicemailState.offered;
      _toast('Could not send the voice message — try again');
      return;
    }
    try {
      await File(path).delete();
    } catch (_) {}
    _vmPath = null;
    voicemail.value = VoicemailState.sent;
    endedText.value = 'Voice message sent';
    _endedTimer?.cancel();
    _endedTimer = Timer(const Duration(milliseconds: 1600), closeEndedScreen);
  }

  /// Same path as a voice note sent from the chat (AudioController.sendAudio): upload, then post
  /// it to the conversation — a driver into their channel, staff into that driver's chat.
  Future<bool> _deliverVoicemail(File file) async {
    final to = _voicemailTo;
    if (to == null) return false;
    try {
      final toDriver = to.driverId != null && to.driverId!.isNotEmpty;
      final channelId = to.channelId ?? info.value?.channelId ?? '';
      final url = toDriver
          ? '${Constant.url}/message/fileUpload?groupId=&userId=${to.driverId}&source='
          : '${Constant.url}/message/fileUpload?groupId=&userId=&source=message';
      final res = await NetworkApiService().fileUpload(file, url, channelId, 'media', false);
      final key = res.data.key;
      if (res.status != true || key == null || key.isEmpty) return false;
      final socketService = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;
      if (socketService == null) return false;
      if (!socketService.isConnected.value) {
        unawaited(socketService.connectSocket());
        final until = DateTime.now().add(const Duration(seconds: 10));
        while (!socketService.isConnected.value && DateTime.now().isBefore(until)) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (!socketService.isConnected.value) return false;
      }
      if (toDriver) {
        socketService.sendMessageToUser(to.driverId!, 'Voice message', key);
      } else {
        socketService.sendMessage('Voice message', key, channelId.isEmpty ? null : channelId, null, null, 'server');
      }
      return true;
    } catch (e) {
      debugPrint('[call] voicemail upload failed: $e');
      return false;
    }
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
    recording.value = false;
    voicemail.value = VoicemailState.none;
    voicemailSeconds.value = 0;
    members.clear();
    pending.clear();
    mutedIds.clear();
    isVideoCall.value = false;
    remoteCamera.clear();
    remoteStreams.clear();
    _resumeCameraOnReturn = false;
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
