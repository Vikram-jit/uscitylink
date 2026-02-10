import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
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
  truckMessage,
}

class HomeController extends GetxController {
  var currentView = SidebarViewType.home.obs;
  var selectedName = "".obs; // holds channel name or user name
  var driverId = "".obs; // holds channel name or user name
  final _channelController = Get.find<ChannelController>();

  var groupId = "".obs;

  void openDirectGroupMessage({
    required String id,
    required String name,
    required String type,
  }) {
    selectedName.value = name;
    groupId.value = id;
    currentView.value = SidebarViewType.truckMessage;

    Get.find<GroupMessageController>().loadMessages(id, 1);

    // final socket = SocketService();

    // socket.emit('staff_active_channel_user_update', userId);
    // socket.emit('staff_open_chat', userId);
    // socket.emit('update_channel_sent_message_count', {
    //   "channelId": _channelController.channels.first.id ?? "-",
    //   "userId": userId,
    // });
  }

  void openDirectMessage({required String userId, required String userName}) {
    selectedName.value = userName;
    driverId.value = userId;
    currentView.value = SidebarViewType.directMessage;

    Get.find<MessageController>().loadMessages(userId, 1);

    final socket = SocketService();

    socket.emit('staff_active_channel_user_update', userId);
    socket.emit('staff_open_chat', userId);
    socket.emit('update_channel_sent_message_count', {
      "channelId": _channelController.channels.first.id ?? "-",
      "userId": userId,
    });
  }

  void openDirectMessageDialog({
    required String userId,
    required String userName,
  }) {
    selectedName.value = userName;
    driverId.value = userId;

    Get.find<MessageController>().loadMessages(userId, 1);

    final socket = SocketService();

    socket.emit('staff_active_channel_user_update', userId);
    socket.emit('staff_open_chat', userId);
    socket.emit('update_channel_sent_message_count', {
      "channelId": _channelController.channels.first.id ?? "-",
      "userId": userId,
    });
  }

  void closeDirectMessageDialog({
    required String userId,
    required String userName,
  }) {
    selectedName.value = "";
    driverId.value = "";

    Get.find<MessageController>().clearChat();

    final socket = SocketService();

    socket.emit('staff_open_chat', "");
  }

  void closeDirectMessage({required String userId, required String userName}) {
    selectedName.value = "";
    driverId.value = "";
    currentView.value = SidebarViewType.home;

    Get.find<MessageController>().clearChat();

    final socket = SocketService();

    socket.emit('staff_open_chat', "");
  }
}
