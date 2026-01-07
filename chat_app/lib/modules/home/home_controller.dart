import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
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

  void openDirectMessage({required String userId, required String userName}) {
    selectedName.value = userName;
    driverId.value = userId;
    currentView.value = SidebarViewType.directMessage;

    Get.find<MessageController>().loadMessages(userId, 1);
    final socket = SocketService();

    socket.emit('staff_active_channel_user_update', userId);
    socket.emit('staff_open_chat', userId);
    socket.emit('update_channel_sent_message_count', {
      "channelId": "1cb8a91e-921f-40fc-873f-af30d2ee3da0",
      "userId": userId,
    });
  }
}
