/// Voice calls (server: server/src/calls, web: web/src/calls).

/// queued = driver called dispatch while every dispatcher was on a call; waiting in line.
enum CallPhase { idle, outgoing, queued, incoming, connecting, active, ended }

class CallPeer {
  final String id;
  final String name;
  final String role; // staff | driver

  const CallPeer({required this.id, required this.name, required this.role});

  factory CallPeer.fromJson(Map<String, dynamic> json) => CallPeer(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        role: '${json['role'] ?? ''}',
      );
}

/// What the server sends with call:incoming / call:resume and in accept/invite acks.
class CallInfo {
  final String callId;
  final String type;
  final String channelId;
  final String channelName;
  final String driverId;
  final CallPeer from;
  final CallPeer? answeredBy;
  final int? answeredAt;

  const CallInfo({
    required this.callId,
    required this.type,
    required this.channelId,
    required this.channelName,
    required this.driverId,
    required this.from,
    this.answeredBy,
    this.answeredAt,
  });

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
        callId: '${json['callId'] ?? ''}',
        type: '${json['type'] ?? 'audio'}',
        channelId: '${json['channelId'] ?? ''}',
        channelName: '${json['channelName'] ?? ''}',
        driverId: '${json['driverId'] ?? ''}',
        from: CallPeer.fromJson(Map<String, dynamic>.from(json['from'] ?? {})),
        answeredBy: json['answeredBy'] is Map ? CallPeer.fromJson(Map<String, dynamic>.from(json['answeredBy'])) : null,
        answeredAt: (json['answeredAt'] as num?)?.toInt(),
      );

  /// From a push (FCM data / VoIP payload / CallKit extra): flat string map.
  factory CallInfo.fromPush(Map<String, dynamic> data) => CallInfo(
        callId: '${data['callId'] ?? ''}',
        type: '${data['callType'] ?? 'audio'}',
        channelId: '${data['channelId'] ?? ''}',
        channelName: '${data['channelName'] ?? ''}',
        driverId: '',
        from: CallPeer(
          id: '${data['callerId'] ?? ''}',
          name: '${data['callerName'] ?? 'Dispatch'}',
          role: '${data['callerRole'] ?? 'staff'}',
        ),
      );
}

String formatCallDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
  return '${h > 0 ? '$h:' : ''}$mm:${s.toString().padLeft(2, '0')}';
}

const callEndedText = {
  'completed': 'Call ended',
  'missed': 'No answer',
  'declined': 'Call declined',
  'cancelled': 'Call cancelled',
  'busy': 'Busy',
  'failed': 'Call failed',
};
