import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:http/http.dart' as http;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/services/call/call_models.dart';

/// Native call UI (iOS CallKit / Android full-screen incoming call) for voice calls.
/// Kept free of registered GetX services: the FCM background handler runs it in a separate isolate
/// when the app is closed (UserPreferenceController is only used to read the saved login).
class CallKit {
  static const ringSeconds = 45;

  /// CallKit doesn't run in the iOS Simulator: there the app's own call screen is used for
  /// everything (and nothing native is shown or ended).
  static bool get available => !(Platform.isIOS && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME'));

  /// Who is calling, as the phone should show it.
  static String callerTitle(CallInfo info) => info.from.role == 'staff'
      ? (info.channelName.isNotEmpty ? info.channelName : 'Dispatch')
      : driverLabel(info.from.name, info.driverPhone);

  /// Also the handle the iPhone's Recents gives back when the call is tapped there, so a driver's is
  /// their phone number: unique per driver (the channel name is shared by every driver on it).
  /// Same wording as ios/Runner/AppDelegate.swift.
  static String callerSubtitle(CallInfo info) => info.from.role == 'staff'
      ? 'Dispatch · ${info.from.name}'
      : 'Driver · ${info.driverPhone.trim().isNotEmpty ? info.driverPhone.trim() : info.channelName}';

  static CallKitParams params(CallInfo info, {bool outgoing = false}) => CallKitParams(
        id: info.callId,
        nameCaller: outgoing ? info.from.name : callerTitle(info),
        appName: 'USCityLink',
        handle: outgoing ? info.channelName : callerSubtitle(info),
        type: info.type == 'video' ? 1 : 0,
        duration: ringSeconds * 1000,
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: 'Missed call',
        ),
        extra: {
          'callId': info.callId,
          'callerId': info.from.id,
          'callerName': info.from.name,
          'callerRole': info.from.role,
          'channelId': info.channelId,
          'channelName': info.channelName,
          'callType': info.type,
          'driverPhone': info.driverPhone,
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          backgroundColor: '#0B1F3A',
          actionColor: '#22C55E',
          textColor: '#FFFFFF',
          incomingCallNotificationChannelName: 'Incoming calls',
          missedCallNotificationChannelName: 'Missed calls',
          isShowFullLockedScreen: true,
          textAccept: 'Accept',
          textDecline: 'Decline',
        ),
        ios: const IOSParams(
          handleType: 'generic',
          supportsVideo: false,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'voiceChat',
          audioSessionActive: true,
          supportsDTMF: false,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          includesCallsInRecents: true,
        ),
      );

  /// Android: a call placed or answered inside the app is registered as an ongoing call. That
  /// starts the plugin's foreground service ("phoneCall|microphone") with the ongoing-call
  /// notification — without it Android silences the microphone as soon as the user switches apps.
  static Future<void> startOngoing({required String callId, required String title, required String subtitle, required bool video}) async {
    if (!Platform.isAndroid || callId.isEmpty) return;
    try {
      await FlutterCallkitIncoming.startCall(CallKitParams(
        id: callId,
        nameCaller: title,
        appName: 'USCityLink',
        handle: subtitle,
        type: video ? 1 : 0,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          backgroundColor: '#0B1F3A',
          actionColor: '#22C55E',
          textColor: '#FFFFFF',
          incomingCallNotificationChannelName: 'Incoming calls',
          missedCallNotificationChannelName: 'Missed calls',
        ),
      ));
      await FlutterCallkitIncoming.setCallConnected(callId);
    } catch (_) {
      // the call itself never depends on this
    }
  }

  static Future<bool> isShowing(String callId) async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      // After a relaunch iOS reports ids in upper case; the server's are lower case
      final id = callId.toLowerCase();
      return calls.any((c) => '${c.id}'.toLowerCase() == id);
    } catch (_) {
      return false;
    }
  }

  static Future<void> showIncoming(CallInfo info) async {
    if (!available || info.callId.isEmpty || await isShowing(info.callId)) return;
    // A push that arrives after the ring window is stale
    await FlutterCallkitIncoming.showCallkitIncoming(params(info));
  }

  /// Android runs the push handler as background work and may freeze or kill the app's process as
  /// soon as it returns. The ringtone plays inside that process, so returning right after showing
  /// the call left the phone silent (app closed, minimised or phone locked). Waits until the call
  /// stops ringing here instead. Pushes are handled one at a time, so a "call ended" push queues
  /// behind this: the server is asked directly whether the call is still the same.
  static Future<void> holdWhileRinging(String callId, int expiresAt) async {
    final until = expiresAt > 0 ? expiresAt : DateTime.now().millisecondsSinceEpoch + ringSeconds * 1000;
    String? firstStatus;
    var tick = 0;
    while (DateTime.now().millisecondsSinceEpoch < until) {
      await Future.delayed(const Duration(seconds: 1));
      if (!await _ringingNatively(callId)) return; // answered, declined or timed out on the phone
      if (++tick % 3 != 0) continue;
      final status = await _serverStatus(callId);
      if (status == null) continue; // offline: the ring timeout still ends it
      // A request to join a group call rings while the call is already "ongoing": only a change
      // means the caller hung up or someone else answered
      firstStatus ??= status;
      if (status != firstStatus) {
        await end(callId);
        return;
      }
    }
  }

  static Future<bool> _ringingNatively(String callId) async {
    try {
      final id = callId.toLowerCase();
      final calls = await FlutterCallkitIncoming.activeCalls();
      return calls.any((c) => '${c.id}'.toLowerCase() == id && c.isAccepted != true);
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _serverStatus(String callId) async {
    try {
      final token = await UserPreferenceController().getToken();
      if (token == null || token.isEmpty) return null;
      final res = await http
          .get(Uri.parse('${Constant.url}/calls/$callId'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      final status = body is Map && body['data'] is Map ? body['data']['status'] : null;
      return status is String ? status : null;
    } catch (_) {
      return null;
    }
  }

  /// Closes the native call screen. Skipped for calls it never showed (outgoing calls, calls
  /// answered in the app): asking CallKit to end an unknown call fails with
  /// "requesttransaction Code=2".
  static Future<void> end(String callId) async {
    if (!available || callId.isEmpty || !await isShowing(callId)) return;
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (_) {}
  }
}

/// FCM handler for when the app is in the background or closed (Android rings via FCM data).
/// Registered in main.dart with FirebaseMessaging.onBackgroundMessage.
@pragma('vm:entry-point')
Future<void> callFirebaseBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  switch (data['type']) {
    case 'CALL_INCOMING':
      final expiresAt = int.tryParse('${data['expiresAt'] ?? ''}') ?? 0;
      if (expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt) return;
      final call = CallInfo.fromPush(Map<String, dynamic>.from(data));
      await CallKit.showIncoming(call);
      if (Platform.isAndroid) await CallKit.holdWhileRinging(call.callId, expiresAt);
      break;
    case 'CALL_ENDED':
      await CallKit.end('${data['callId'] ?? ''}');
      break;
  }
}
