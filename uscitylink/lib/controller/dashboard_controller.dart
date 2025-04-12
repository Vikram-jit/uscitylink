import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/model/staff/staff_dashboard_model.dart';
import 'package:uscitylink/services/dashboard_service.dart';
import 'package:uscitylink/utils/utils.dart';

class DashboardController extends GetxController {
  DashboardService _dashboardService = DashboardService();

  final dashboard = DashboardModel().obs;
  final dashboardStaff = StaffDashboardModel().obs;
  var loading = false.obs;
  final channel = Channel().obs;
  @override
  void onInit() async {
    super.onInit();
  }

  void getDashboard() async {
    Box<DashboardModel> dashboardBox =
        await Hive.openBox<DashboardModel>('dashboardBox');

    loading.value = true;
    _dashboardService.getDashboard().then((response) {
      dashboard.value = response.data;
      dashboardBox.put('dashboardBox', response.data);
      loading.value = false;
    }).onError((error, stackTrace) {
      if (error.toString() == "Exception: No Internet Connection") {
        DashboardModel? cachedDashboard = dashboardBox.get('dashboardBox');
        if (cachedDashboard != null) {
          dashboard.value = cachedDashboard;
        }
        loading.value = false;
      }
      loading.value = false;
      // Utils.snackBar('Error', error.toString());
    });
  }

  void getStaffDashboard() {
    loading.value = true;
    _dashboardService.getDashboardStaff().then((response) {
      dashboardStaff.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }
}
