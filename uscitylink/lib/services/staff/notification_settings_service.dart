import 'package:uscitylink/services/staff/staff_api_client.dart';

/// Whether one kind of alert (messages or calls) is muted, and until when.
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

  /// A timed mute that has run out counts as on, even before the next refresh.
  bool get active => muted && (forever || until == null || until!.isAfter(DateTime.now()));
}

enum MuteKind { messages, calls }

/// Message mute and call mute are separate: muting messages never stops calls ringing.
class NotificationSettings {
  final NotificationMute messages;
  final NotificationMute calls;
  const NotificationSettings({this.messages = const NotificationMute(), this.calls = const NotificationMute()});
}

/// Staff → Settings → Notifications. The server skips the push while muted; messages and unread
/// counts are unaffected. Call mute stops calls ringing this phone (the web dashboard still rings).
class NotificationSettingsService {
  final _api = StaffApiClient();

  NotificationSettings _parse(Map<String, dynamic> res) {
    final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    return NotificationSettings(
      messages: NotificationMute.fromJson(data),
      calls: NotificationMute.fromJson(Map<String, dynamic>.from(data['calls'] as Map? ?? {})),
    );
  }

  Future<NotificationSettings> get() async => _parse(await _api.get('user/notification-mute'));

  /// [minutes] null with [forever] false turns that kind back on.
  Future<NotificationSettings> set({MuteKind kind = MuteKind.messages, int? minutes, bool forever = false}) async =>
      _parse(await _api.put('user/notification-mute', {
        'minutes': minutes,
        'forever': forever,
        if (kind == MuteKind.calls) 'kind': 'calls',
      }));
}
