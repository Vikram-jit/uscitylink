import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uscitylink/services/call/call_models.dart';

/// Native call UI (iOS CallKit / Android full-screen incoming call) for voice calls.
/// Kept free of GetX/controllers: the FCM background handler runs it in a separate isolate when
/// the app is closed.
class CallKit {
  static const ringSeconds = 45;

  /// CallKit doesn't run in the iOS Simulator: there the app's own call screen is used for
  /// everything (and nothing native is shown or ended).
  static bool get available => !(Platform.isIOS && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME'));

  /// Who is calling, as the phone should show it.
  static String callerTitle(CallInfo info) =>
      info.from.role == 'staff' ? (info.channelName.isNotEmpty ? info.channelName : 'Dispatch') : info.from.name;

  static String callerSubtitle(CallInfo info) =>
      info.from.role == 'staff' ? 'Dispatch · ${info.from.name}' : 'Driver · ${info.channelName}';

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

  static Future<bool> isShowing(String callId) async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      return calls.any((c) => c.id == callId);
    } catch (_) {
      return false;
    }
  }

  static Future<void> showIncoming(CallInfo info) async {
    if (!available || info.callId.isEmpty || await isShowing(info.callId)) return;
    // A push that arrives after the ring window is stale
    await FlutterCallkitIncoming.showCallkitIncoming(params(info));
  }

  static Future<void> end(String callId) async {
    if (!available) return;
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
      await CallKit.showIncoming(CallInfo.fromPush(Map<String, dynamic>.from(data)));
      break;
    case 'CALL_ENDED':
      await CallKit.end('${data['callId'] ?? ''}');
      break;
  }
}
