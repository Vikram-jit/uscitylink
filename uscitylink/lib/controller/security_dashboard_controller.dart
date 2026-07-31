import 'package:get/get.dart';
import 'package:uscitylink/model/security_dashboard_model.dart';
import 'package:uscitylink/services/security_dashboard_service.dart';
import 'package:uscitylink/utils/utils.dart';

class SecurityDashboardController extends GetxController {
  final _securityDashboardService = SecurityDashboardService();

  final dashboard = SecurityDashboardModel().obs;
  var loading = false.obs;

  void getDashboard() {
    loading.value = true;
    _securityDashboardService.getDashboard().then((response) {
      dashboard.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }
}
