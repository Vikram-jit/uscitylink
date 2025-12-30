import 'package:get/get.dart';

class SidebarController extends GetxController {
  var showProfileMenu = false.obs;

  void toggleProfileMenu() {
    showProfileMenu.value = !showProfileMenu.value;
  }

  void closeMenu() {
    showProfileMenu.value = false;
  }
}
