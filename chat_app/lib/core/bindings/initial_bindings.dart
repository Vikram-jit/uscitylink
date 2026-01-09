import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/controller/global_socket_controller.dart';
import 'package:chat_app/core/services/user_interaction_service.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(UserInteractionService(), permanent: true);

    Get.put(GlobalSocketController(), permanent: true);
    Get.lazyPut<ChannelController>(() => ChannelController(), fenix: true);
    Get.put(HomeController());

    Get.put(OverviewController());
    Get.lazyPut<MessageController>(() => MessageController(), fenix: true);
    Get.put(GlobalSearchController(), permanent: true);
  }
}
