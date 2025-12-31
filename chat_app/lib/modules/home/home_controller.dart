import 'package:get/get.dart';

enum SidebarViewType { home, channel, directMessage, directory }

class HomeController extends GetxController {
  var currentView = SidebarViewType.home.obs;
  var selectedName = "".obs; // holds channel name or user name
  var driverId = "".obs; // holds channel name or user name
}
