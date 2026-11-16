import 'package:get/get.dart';
import 'package:uscitylink/model/staff/driver_pagination_model.dart';
import 'package:uscitylink/model/template_model.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/utils/staff_feedback.dart';

class StaffDriverController extends GetxController {
  /// [loadPage] and [api] are for tests; the app uses the channel service and the staff API client.
  StaffDriverController({Future<DriverPaginationModel> Function(int page)? loadPage, StaffApiClient? api})
      : _loadPage = loadPage,
        _api = api ?? StaffApiClient();
  final Future<DriverPaginationModel> Function(int page)? _loadPage;
  final StaffApiClient _api;

  var drivers = <Driver>[].obs;
  var templates = <Template>[].obs;

  final __channelService = ChannelService();
  var loading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  void getDriver(int page) {
    loading.value = true;
    final load = _loadPage != null ? _loadPage!(page) : __channelService.getDrivers(page).then((r) => r.data);
    load.then((data) {
      drivers.addAll(data.driver ?? []);
      currentPage.value = data.pagination!.currentPage!;
      totalPages.value = data.pagination!.totalPages!;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      staffSnackBar('Error', error.toString());
    });
  }

  /// Turn calling on / off for one driver: drivers see the call buttons and may call dispatch only while
  /// it is on. Staff can always call drivers. Shown at once, put back if the server says no.
  Future<bool> setCalling(Driver driver, bool on) async {
    final user = driver.user;
    if (user == null || driver.id == null) return false;
    final before = user.callsEnabled;
    user.callsEnabled = on;
    drivers.refresh();
    try {
      await _api.put('calls/drivers/${driver.id}', {'enabled': on});
      staffSnackBar('Calling', '${driver.username ?? 'Driver'} ${on ? 'can now call dispatch' : "can't call dispatch any more"}');
      return true;
    } catch (e) {
      user.callsEnabled = before;
      drivers.refresh();
      staffSnackBar('Calling not changed', e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }
}
