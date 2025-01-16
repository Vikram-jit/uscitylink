import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/staff_services/chat_service.dart';
import 'package:uscitylink/utils/utils.dart';

class StaffchatController {
  SocketService _socketService = Get.find<SocketService>();
  var message = UserMessageModel().obs;
  TextEditingController messageController = TextEditingController();
  var templateUrl = "".obs;
  final __channelService = ChatService();
  var typing = false.obs;
  var typingMessage = "".obs;
  var loading = false.obs;
  var userId = "".obs;
  var channelId = "".obs;
  var userName = "".obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  Timer? typingTimer;
  late DateTime typingStartTime;

  Future<void> getChannelMembers(String id, int page, String channelId) async {
    if (loading.value) return; // Prevent multiple simultaneous requests

    loading.value = true;

    try {
      // Fetch messages from the server with pagination.
      var response = await __channelService.getMesssageByUserId(
          page: page, id: id, pageSize: 10, channelId: channelId);

      // Check if the response is valid
      if (response.data != null) {
        // Append new messages if it's not the first page
        if (page > 1) {
          message.value.messages?.addAll(response.data.messages ?? []);
        } else {
          // Reset the message list if it's the first page
          message.value = response.data;
        }

        // Update pagination info
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        Utils.snackBar('No data', 'No messages found.');
      }
    } catch (error) {
      // Handle error by showing a snack bar
      Utils.snackBar('Error', error.toString());
    } finally {
      // Ensure loading state is reset
      loading.value = false;
    }
  }

  void updateChannelMessagesByNotification(
      String newChannelId, String channelName, String id) {
    _socketService.updateStaffActiveUserChat("");
    channelId.value = newChannelId;
    userName.value = channelName;
    userId.value = id;
    currentPage.value = 1;
    totalPages.value = 1;
    if (_socketService.isConnected.value) {
      _socketService.updateStaffActiveUserChat(id);
    }
    getChannelMembers(id, 1, newChannelId);
  }

  Future<void> deleteMember(String id) async {
    if (loading.value) return;

    loading.value = true;

    try {
      // Fetch messages from the server with pagination.
      var response = await __channelService.deletedById(id);

      // Check if the response is valid
      if (response.status) {
        Utils.toastMessage(response.message);
      }
    } catch (error) {
      // Handle error by showing a snack bar
      Utils.snackBar('Error', error.toString());
    } finally {
      // Ensure loading state is reset
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
