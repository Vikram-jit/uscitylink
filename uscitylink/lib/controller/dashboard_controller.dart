import 'package:get/get.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/services/dashboard_service.dart';
import 'package:uscitylink/utils/utils.dart';

class DashboardController extends GetxController {
  DashboardService _dashboardService = DashboardService();

  final dashboard = DashboardModel().obs;
  var loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getDashboard();
  }

  void getDashboard() {
    loading.value = true;
    _dashboardService.getDashboard().then((response) {
      print(response);
      dashboard.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }
}
