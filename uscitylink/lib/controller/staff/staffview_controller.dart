import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';

class StaffviewController extends GetxController {
  var currentIndex = 0.obs;
  final StaffchannelController _staffchannelController =
      Get.put(StaffchannelController());
  final DashboardController _dashboardController =
      Get.put(DashboardController());
  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      if (index == 0) {
        _dashboardController.getStaffDashboard();
      }
      if (index == 1) {
        _staffchannelController.getChnnelChatUser(
            _staffchannelController.currentPage.value,
            _staffchannelController.searchController.text);
      }
      if (index == 2) {}
      if (index == 3) {
        _staffchannelController.getUserChannels();
      }
    });
  }

  void setTabIndex(int index) {
    currentIndex.value = index;
  }
}
