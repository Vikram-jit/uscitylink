import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/staff_services/chat_service.dart';
import 'package:uscitylink/utils/utils.dart';

class StaffchatController {
  SocketService _socketService = Get.find<SocketService>();
  var message = UserMessageModel().obs;
  TextEditingController messageController = TextEditingController();
  final __channelService = ChatService();
  var typing = false.obs;
  var typingMessage = "".obs;
  var loading = false.obs;
  var userId = "".obs;
  var channelId = "".obs;
  var userName = "".obs;

  Timer? typingTimer;
  late DateTime typingStartTime;

  Future<void> getChannelMembers(String id) async {
    loading.value = true;

    try {
      var response = await __channelService.getMesssageByUserId(id);

      message.value = response.data;
      loading.value = false;
    } catch (error) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  void updateTypingStatus(dynamic data) {
    typing.value = data['isTyping'];
    typingMessage.value = data['message'];
  }

  void startTyping(String userId) {
    if (typingTimer != null && typingTimer!.isActive) {
      typingTimer!.cancel();
    }

    _socketService.staffTyping(userId, true);

    typingStartTime = DateTime.now();

    typingTimer = Timer(const Duration(seconds: 1), () {
      if (DateTime.now().difference(typingStartTime).inSeconds >= 1) {
        stopTyping(userId);
      }
    });
  }

  // Stop typing event
  void stopTyping(String userId) {
    _socketService.staffTyping(userId, false);
  }

  void onNewMessage(dynamic data) {
    MessageModel newMessage = MessageModel.fromJson(data);

    if (userId.value == newMessage.userProfileId) {
      message.value.messages?.insert(0, newMessage);
      message?.refresh();
    }
  }
}
