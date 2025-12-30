import 'package:get/get.dart';

class MessageController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins

  void switchTab(int index) {
    currentTab.value = index;
  }
}
