import 'package:chat_app/core/controller/global_loader_controller.dart';
import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/controller/global_socket_controller.dart';
import 'package:chat_app/core/services/user_interaction_service.dart';
import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    /// SERVICES
    Get.put(UserInteractionService(), permanent: true);
    Get.put(GlobalSocketController(), permanent: true);
    Get.put(GlobalSearchController(), permanent: true);

    /// HOME
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<OverviewController>(() => OverviewController(), fenix: true);
    Get.lazyPut<ChannelController>(() => ChannelController(), fenix: true);
    Get.lazyPut<MessageController>(() => MessageController(), fenix: true);

    /// GROUP CHAT
    Get.lazyPut<GroupController>(() => GroupController(), fenix: true);
    Get.lazyPut<GroupMessageController>(
      () => GroupMessageController(),
      fenix: true,
    );
    Get.lazyPut<BroadcastController>(
      () => BroadcastController(),
      fenix: true, // ✅ important
    );

    Get.put(GlobalLoaderController(), permanent: true);
  }
}
