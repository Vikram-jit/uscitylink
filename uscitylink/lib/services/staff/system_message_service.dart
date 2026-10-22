import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';

/// Result of trying to complete a system message.
class CompleteResult {
  final bool ok;
  final bool requiresNote;
  final String message;
  CompleteResult(this.ok, this.requiresNote, this.message);
}

/// System messages (yard gate events) — the same endpoints the web "System Messages" page uses.
class SystemMessageService {
  final _api = StaffApiClient();

  Future<({List<SystemMessage> messages, int totalPages})> list({
    int page = 1,
    int pageSize = 15,
    String search = '',
    String completedBy = '',
    String startDate = '',
    String endDate = '',
  }) async {
    final res = await _api.get('message/system', {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'completedBy': completedBy,
      'startDate': startDate,
      'endDate': endDate,
    });
    final data = res['data'] as Map? ?? {};
    final messages = (data['messages'] as List? ?? [])
        .whereType<Map>()
        .map((e) => SystemMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final totalPages = ((data['pagination'] as Map?)?['totalPages'] as num?)?.toInt() ?? 1;
    return (messages: messages, totalPages: totalPages);
  }

  Future<List<SystemMessage>> unread() async {
    final res = await _api.get('message/system/unread');
    return ((res['data'] as Map?)?['messages'] as List? ?? [])
        .whereType<Map>()
        .map((e) => SystemMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Mark completed. If no matching gate log is found the server asks for a note (min 10 chars).
  Future<CompleteResult> complete(String id, {String? note}) async {
    try {
      final res = await _api.put('message/system/$id/complete', {if (note != null) 'note': note});
      return CompleteResult(true, false, (res['message'] ?? 'Message marked as completed.').toString());
    } on StaffApiError catch (e) {
      return CompleteResult(false, e.body['requiresNote'] == true, e.message);
    }
  }

  Future<List<StaffUser>> staffUsers() async {
    final res = await _api.get('user', {'role': 'staff', 'page': -1, 'search': ''});
    final users = ((res['data'] as Map?)?['users'] as List? ?? []).whereType<Map>();
    return users
        .map((u) => StaffUser(
              u['id'].toString(),
              (u['username'] ?? (u['user'] is Map ? u['user']['email'] : null) ?? u['id']).toString(),
            ))
        .toList();
  }
}
