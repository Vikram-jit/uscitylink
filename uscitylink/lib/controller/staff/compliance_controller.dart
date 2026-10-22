import 'package:get/get.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/services/staff/compliance_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/utils/staff_feedback.dart';

/// Scale checks, routes, equipment and weight rules for the staff app (same data as web Compliance).
class ComplianceController extends GetxController {
  final _service = ComplianceService();

  // Scale checks
  final checks = <ScaleCheck>[].obs;
  final pendingCount = 0.obs;
  final filter = 'pending'.obs; // 'pending' = waiting for dispatch, '' = all
  final loading = false.obs;
  final busy = false.obs;
  int _page = 1;
  int _total = 0;

  // Equipment and rules
  final equipment = <EquipmentProfile>[].obs;
  final rules = <WeightRuleSet>[].obs;
  final equipmentLoading = false.obs;
  final rulesLoading = false.obs;

  bool get hasMore => checks.length < _total;

  /// Count for the dashboard / drawer badge.
  Future<void> refreshPendingCount() async {
    try {
      final res = await _service.scaleChecks(page: 1, approval: 'pending');
      pendingCount.value = res.pending;
    } catch (_) {
      // Badge only: keep the last value if offline
    }
  }

  Future<void> loadChecks({bool reset = true}) async {
    if (loading.value) return;
    loading.value = true;
    try {
      if (reset) _page = 1;
      final res = await _service.scaleChecks(page: _page, approval: filter.value.isEmpty ? null : filter.value);
      pendingCount.value = res.pending;
      _total = res.total;
      if (reset) {
        checks.assignAll(res.checks);
      } else {
        final known = checks.map((c) => c.id).toSet();
        checks.addAll(res.checks.where((c) => !known.contains(c.id)));
      }
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loading.value) return;
    _page += 1;
    await loadChecks(reset: false);
  }

  void setFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    loadChecks();
  }

  /// Fetch one check fresh (detail screen).
  Future<ScaleCheck?> reloadCheck(ScaleCheck check) async {
    try {
      final fresh = await _service.scaleCheckForMessage(check.messageId);
      if (fresh != null) _replace(fresh);
      return fresh;
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  void _replace(ScaleCheck fresh) {
    final i = checks.indexWhere((c) => c.id == fresh.id);
    if (i >= 0) checks[i] = fresh;
  }

  /// Release ('approve') or reject. Returns true on success.
  Future<bool> decide(ScaleCheck check, String decision, {String? note}) =>
      _act(() => _service.decide(check.id, decision, note: note), check);

  Future<bool> recheck(ScaleCheck check) => _act(() async {
        await _service.recheck(check.id);
        return 'Re-checked';
      }, check);

  Future<bool> recordAdjustment(ScaleCheck check, String action, int? holes) => _act(
        () => _service.recordAdjustment(check.id, action: action, holes: holes, parkedConfirmed: true),
        check,
      );

  Future<bool> _act(Future<String> Function() run, ScaleCheck check) async {
    if (busy.value) return false;
    busy.value = true;
    try {
      final message = await run();
      Utils.toastMessage(message);
      await reloadCheck(check);
      await refreshPendingCount();
      // Released / rejected tickets leave the "Waiting for dispatch" list
      if (filter.value == 'pending') checks.removeWhere((c) => c.id == check.id && !c.isPending);
      return true;
    } catch (e) {
      staffSnackBar('Not saved', e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      busy.value = false;
    }
  }

  // Routes
  Future<DriverTrip?> driverTrip(String driverId) async {
    try {
      return await _service.driverTrip(driverId);
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  Future<bool> saveDriverTrip(String driverId, DriverTrip trip) async {
    busy.value = true;
    try {
      Utils.toastMessage(await _service.saveDriverTrip(driverId, trip));
      await refreshPendingCount();
      return true;
    } catch (e) {
      staffSnackBar('Route not saved', e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> closeDriverTrip(String driverId) async {
    try {
      await _service.closeDriverTrip(driverId);
      Utils.toastMessage('Trip closed');
      return true;
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Equipment
  Future<void> loadEquipment() async {
    equipmentLoading.value = true;
    try {
      equipment.assignAll(await _service.equipment());
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      equipmentLoading.value = false;
    }
  }

  Future<bool> saveEquipment(EquipmentProfile profile) async {
    busy.value = true;
    try {
      Utils.toastMessage(await _service.saveEquipment(profile));
      await loadEquipment();
      return true;
    } catch (e) {
      staffSnackBar('Not saved', e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> deleteEquipment(EquipmentProfile profile) async {
    try {
      await _service.deleteEquipment(profile.id!);
      equipment.removeWhere((e) => e.id == profile.id);
      Utils.toastMessage('Removed ${profile.unitNumber}');
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Weight rules
  Future<void> loadRules() async {
    rulesLoading.value = true;
    try {
      final list = await _service.ruleSets();
      list.sort((a, b) => (b.active ? 1 : 0) - (a.active ? 1 : 0));
      rules.assignAll(list);
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      rulesLoading.value = false;
    }
  }

  Future<void> reviewRule(WeightRuleSet rule) async {
    try {
      Utils.toastMessage(await _service.reviewRuleSet(rule.id));
      await loadRules();
    } catch (e) {
      staffSnackBar('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
