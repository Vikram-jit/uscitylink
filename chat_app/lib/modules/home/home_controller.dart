import 'package:get/get.dart';

enum SidebarViewType {
  home,
  channel,
  channelMembers,
  template,
  driver,
  directMessage,
  directory,
  users,
}

class HomeController extends GetxController {
  var currentView = SidebarViewType.home.obs;
  var selectedName = "".obs; // holds channel name or user name
  var driverId = "".obs; // holds channel name or user name
}
