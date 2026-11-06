import 'package:uscitylink/services/staff/staff_api_client.dart';

/// One row of the call log (GET /calls), the same list the web dashboard shows.
class CallLogEntry {
  final String id;
  final String type;
  final String status;
  final String direction; // driver_to_dispatch | dispatch_to_driver
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String initiatorName;
  final String answeredByName;
  final int rangCount;
  final int people;
  final DateTime? startedAt;
  final int durationSec;
  final int? waitSec;
  final int queuedSec;
  final String endReason;
  final bool recorded;

  const CallLogEntry({
    required this.id,
    this.type = 'audio',
    required this.status,
    required this.direction,
    required this.driverId,
    this.driverName = '',
    this.driverPhone = '',
    this.initiatorName = '',
    this.answeredByName = '',
    this.rangCount = 0,
    this.people = 0,
    this.startedAt,
    this.durationSec = 0,
    this.waitSec,
    this.queuedSec = 0,
    this.endReason = '',
    this.recorded = false,
  });

  bool get fromDriver => direction == 'driver_to_dispatch';
  bool get missed => const ['missed', 'cancelled', 'declined', 'busy', 'failed'].contains(status);

  /// "driver → dispatch" or "Navjot → driver" (same wording as the web dashboard)
  String get directionLabel => fromDriver ? 'driver → dispatch' : '${initiatorName.isEmpty ? 'Dispatch' : initiatorName} → driver';

  static String _s(dynamic v) => v == null ? '' : '$v';
  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

  factory CallLogEntry.fromJson(Map<String, dynamic> j) => CallLogEntry(
        id: _s(j['id']),
        type: _s(j['type']).isEmpty ? 'audio' : _s(j['type']),
        status: _s(j['status']),
        direction: _s(j['direction']),
        driverId: _s(j['driver_id']),
        driverName: _s(j['driver_name']),
        driverPhone: _s(j['driver_phone']).trim(),
        initiatorName: _s(j['initiator_name']),
        answeredByName: _s(j['answered_by_name']),
        rangCount: _i(j['rang_count']),
        people: _i(j['people']),
        startedAt: DateTime.tryParse(_s(j['started_at']))?.toLocal(),
        durationSec: _i(j['duration_sec']),
        waitSec: j['wait_sec'] == null ? null : _i(j['wait_sec']),
        queuedSec: _i(j['queued_sec']),
        endReason: _s(j['end_reason']),
        recorded: j['recording'] is Map && j['recording']['status'] == 'ready',
      );
}

/// Who a call rang / who joined, for the details sheet (GET /calls/:id).
class CallLogPerson {
  final String name;
  final String role; // caller | callee | added
  final String outcome; // answered | declined | missed | left | joined | cancelled | caller
  const CallLogPerson(this.name, this.role, this.outcome);
}

/// The call's recording as stored (GET /calls/:id → recording).
class CallRecordingInfo {
  final String status; // recording | processing | ready | failed
  final String error;
  final String sha256;
  final bool hasVideo;
  final int? durationSec;
  const CallRecordingInfo({required this.status, this.error = '', this.sha256 = '', this.hasVideo = false, this.durationSec});

  static CallRecordingInfo? fromJson(dynamic j) => j is Map
      ? CallRecordingInfo(
          status: '${j['status'] ?? ''}',
          error: '${j['error'] ?? ''}',
          sha256: '${j['sha256'] ?? ''}',
          hasVideo: j['has_video'] == true,
          durationSec: (j['duration_sec'] as num?)?.toInt(),
        )
      : null;
}

/// Short-lived links to play / download a recording (GET /calls/:id/recording; expire in 15 min).
class CallRecordingLink {
  final String url;
  final String videoUrl;
  final String sha256;
  final String videoSha256;
  const CallRecordingLink({required this.url, this.videoUrl = '', this.sha256 = '', this.videoSha256 = ''});
}

class CallLogDetail {
  final List<CallLogPerson> people;
  final CallRecordingInfo? recording;
  const CallLogDetail(this.people, this.recording);
}

class CallLogPage {
  final List<CallLogEntry> calls;
  final int total;
  const CallLogPage(this.calls, this.total);
}

class CallLogService {
  final _api = StaffApiClient();

  /// [status]: null = all, or a comma list ("missed,cancelled,declined,busy", "completed").
  Future<CallLogPage> list({String? status, int page = 1, int pageSize = 30}) async {
    final res = await _api.get('calls', {'status': status, 'page': page, 'pageSize': pageSize});
    final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    final calls = (data['calls'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => CallLogEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return CallLogPage(calls, (data['total'] as num?)?.toInt() ?? calls.length);
  }

  Future<CallLogDetail> detail(String callId) async {
    final res = await _api.get('calls/$callId');
    final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    final people = (data['participants'] as List? ?? const [])
        .whereType<Map>()
        .map((p) => CallLogPerson('${p['name'] ?? 'Someone'}', '${p['role'] ?? ''}', '${p['outcome'] ?? ''}'))
        .toList();
    return CallLogDetail(people, CallRecordingInfo.fromJson(data['recording']));
  }

  Future<CallRecordingLink> recordingLink(String callId) async {
    final res = await _api.get('calls/$callId/recording');
    final d = Map<String, dynamic>.from(res['data'] as Map? ?? {});
    return CallRecordingLink(
      url: '${d['url'] ?? ''}',
      videoUrl: '${d['video_url'] ?? ''}',
      sha256: '${d['sha256'] ?? ''}',
      videoSha256: '${d['video_sha256'] ?? ''}',
    );
  }
}
