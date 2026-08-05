import 'package:get/get.dart';
import 'package:uscitylink/model/hos_status_model.dart';
import 'package:uscitylink/services/dashboard_service.dart';

/// Real-time Hours of Service clocks (drive time left, on-duty, cycle,
/// break). Deliberately not cached to Hive the way [DashboardController] is —
/// this is a compliance-relevant, minute-by-minute number, and showing a
/// stale cached "time left" while offline would be actively misleading
/// rather than just out of date.
class HosController extends GetxController {
  final DashboardService _dashboardService = DashboardService();

  final hosStatus = HosStatusModel().obs;
  var loading = false.obs;
  var hasError = false.obs;

  void getHosStatus() async {
    loading.value = true;
    hasError.value = false;
    _dashboardService.getHosStatus().then((response) {
      hosStatus.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      hasError.value = true;
      loading.value = false;
    });
  }
}
