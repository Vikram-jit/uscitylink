import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';

/// Compliance (scale agent) API — the same endpoints the web Compliance pages use.
class ComplianceService {
  final _api = StaffApiClient();

  Future<({List<ScaleCheck> checks, int pending, int total})> scaleChecks({int page = 1, String? approval}) async {
    final res = await _api.get('automation/scale-checks', {'page': page, 'pageSize': 25, 'approval': approval});
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final checks = (data['checks'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ScaleCheck.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final pagination = data['pagination'] as Map? ?? {};
    return (
      checks: checks,
      pending: (data['pending'] as num?)?.toInt() ?? 0,
      total: (pagination['total'] as num?)?.toInt() ?? checks.length,
    );
  }

  Future<ScaleCheck?> scaleCheckForMessage(String messageId) async {
    final res = await _api.get('automation/scale-checks/by-message/$messageId');
    final data = res['data'];
    return data is Map ? ScaleCheck.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  Future<String> decide(String id, String decision, {String? note}) async {
    final res = await _api.post('automation/scale-checks/$id/$decision', {'note': note});
    return (res['message'] ?? 'Saved').toString();
  }

  Future<void> recheck(String id) => _api.post('automation/scale-checks/$id/recheck');

  Future<String> recordAdjustment(String id, {required String action, int? holes, required bool parkedConfirmed}) async {
    final res = await _api.post('automation/scale-checks/$id/adjustment', {
      'action': action,
      'holes': holes,
      'parked_confirmed': parkedConfirmed,
    });
    return (res['message'] ?? 'Recorded').toString();
  }

  Future<DriverTrip?> driverTrip(String driverId) async {
    final res = await _api.get('automation/trips/driver/$driverId');
    final data = res['data'];
    return data is Map ? DriverTrip.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  Future<String> saveDriverTrip(String driverId, DriverTrip trip) async {
    final res = await _api.put('automation/trips/driver/$driverId', trip.toJson());
    return (res['message'] ?? 'Route saved').toString();
  }

  Future<void> closeDriverTrip(String driverId) => _api.post('automation/trips/driver/$driverId/close');

  Future<List<EquipmentProfile>> equipment() async {
    final res = await _api.get('automation/equipment');
    return (res['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => EquipmentProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> saveEquipment(EquipmentProfile profile) async {
    final res = profile.id == null
        ? await _api.post('automation/equipment', profile.toJson())
        : await _api.put('automation/equipment/${profile.id}', profile.toJson());
    return (res['message'] ?? 'Saved').toString();
  }

  Future<void> deleteEquipment(String id) => _api.delete('automation/equipment/$id');

  Future<List<WeightRuleSet>> ruleSets() async {
    final res = await _api.get('automation/rule-sets');
    return (res['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => WeightRuleSet.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> reviewRuleSet(String id) async {
    final res = await _api.post('automation/rule-sets/$id/review');
    return (res['message'] ?? 'Marked reviewed').toString();
  }
}
