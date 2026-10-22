import 'package:uscitylink/services/staff/staff_api_client.dart';

/// Whether this login's push notifications are muted, and until when.
class NotificationMute {
  final bool muted;
  final DateTime? until;
  final bool forever;
  const NotificationMute({this.muted = false, this.until, this.forever = false});

  factory NotificationMute.fromJson(Map<String, dynamic> json) => NotificationMute(
        muted: json['muted'] == true,
        until: DateTime.tryParse('${json['mutedUntil'] ?? ''}')?.toLocal(),
        forever: json['forever'] == true,
      );
}

/// Staff → Settings → Notifications. The server skips the push while muted; messages and unread
/// counts are unaffected.
class NotificationSettingsService {
  final _api = StaffApiClient();

  NotificationMute _parse(Map<String, dynamic> res) =>
      NotificationMute.fromJson(Map<String, dynamic>.from(res['data'] as Map? ?? {}));

  Future<NotificationMute> get() async => _parse(await _api.get('user/notification-mute'));

  /// [minutes] null with [forever] false turns notifications back on.
  Future<NotificationMute> set({int? minutes, bool forever = false}) async =>
      _parse(await _api.put('user/notification-mute', {'minutes': minutes, 'forever': forever}));
}
