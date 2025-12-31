import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
    Get.put(OverviewController());
    Get.put(MessageController());
  }
}
