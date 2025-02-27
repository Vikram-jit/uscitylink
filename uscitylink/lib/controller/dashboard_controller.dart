import 'dart:convert';

import 'package:get/get.dart';
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
  void onInit() {
    super.onInit();
    //getDashboard();
  }

  void getDashboard() {
    loading.value = true;
    _dashboardService.getDashboard().then((response) {
      dashboard.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
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
