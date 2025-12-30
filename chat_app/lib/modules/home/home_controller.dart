import 'package:get/get.dart';

enum SidebarViewType { channel, directMessage, directory }

class HomeController extends GetxController {
  var currentView = SidebarViewType.channel.obs;
  var selectedName = "".obs; // holds channel name or user name
}
