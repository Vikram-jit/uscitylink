import 'dart:async';
import 'dart:convert';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/models/group_message_response_model.dart';
import 'package:chat_app/models/group_response_model.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupMessageController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  final messages = <Messages>[].obs;
  final isLoading = false.obs;
  final memmbers = <GroupMembers>[].obs;
  final senderId = "".obs;
  final group = GroupModel().obs;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;

  final isAtBottom = true.obs;
  final showScrollToBottomButton = false.obs;
  final scrollButtonTitle = "New Message".obs;

  var errorText = "".obs;

  final hasMore = true.obs;

  int totalPages = 1;

  final ScrollController scrollController = ScrollController();
  final channelId = "".obs;

  HomeController _homeController = Get.find<HomeController>();
  final msgInputController = TextEditingController();
  final msgText = "".obs;

  final typingMsg = "".obs;
  final isTyping = false.obs;

  final isTypingStaff = false.obs;
  DateTime? _typingStartTime;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();
    listenIncomingMessages();
    listenDriverTypling();
    scrollController.addListener(_onScroll);
    msgInputController.addListener(() {
      msgText.value = msgInputController.text.trim();
    });
  }

  void onKeyPressed() {
    if (!isTypingStaff.value) {
      isTypingStaff.value = true;
      sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      isTypingStaff.value = false;
      sendTypingStatus(false);
    });
  }

  void sendTypingStatus(bool typing) async {
    SocketService().emit('typing', {
      'isTyping': typing,
      'userId': _homeController.driverId.value,
    });
  }

  void _onScroll() {
    print("SCROLL: ${scrollController.position.pixels}");
    print("MAX: ${scrollController.position.maxScrollExtent}");

    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 50 &&
        !isLoading.value &&
        hasMore.value) {
      print("LOAD MORE TRIGGERED");
      loadMore(_homeController.groupId.value);
    }
  }

  Future<void> loadMore(String userId) async {
    if (!hasMore.value || isLoading.value) return;

    currentPage.value++;

    await _fetch(userId, currentPage.value);
  }

  void switchTab(int index) {
    currentTab.value = index;
  }

  clearChat() {
    currentPage.value = 1;
    memmbers.clear();
    senderId.value = "";
    group.value = GroupModel();
    messages.clear();
    totalItems = 0;
  }

  Future<void> loadMessages(String groupId, int page) async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      isLoading.value = true;
      currentPage.value = page;

      final res = await MessageService().getGroupMessages(groupId, page);

      if (res.status) {
        memmbers.value = res.data?.members ?? [];
        senderId.value = res.data?.senderId ?? "";
        group.value = res.data?.group ?? GroupModel();
        messages.assignAll(res.data?.messages ?? []);
        totalItems = res.data?.pagination?.total ?? 0;
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetch(String userId, int page) async {
    try {
      isLoading.value = true;

      final res = await MessageService().getGroupMessages(userId, page);
      if (res.status) {
        final pagination = res.data?.pagination;

        messages.addAll(res.data?.messages ?? []);

        hasMore.value =
            (pagination?.currentPage ?? 1) < (pagination?.totalPages ?? 1);

        totalPages = pagination?.totalPages ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage({
    required String body,
    String? replyMessageId,
    String? url,
    String? thumbnail,
  }) {
    print("------");
    String userIds = memmbers
        .where((e) => e.status == "active")
        .map((e) => e.userProfileId) // or e.id depending on your model
        .join(",");
    print(userIds);
    SocketService().emit('send_message_to_user_by_group', {
      "userId": userIds,
      "groupId": group.value.id,
      "body": body,
      "direction": 'S',
      "url": '',
    });
    print("------");
    msgInputController.clear();
  }

  void listenIncomingMessages() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('receive_message_group_truck');

    socket.on('receive_message_group_truck', (data) {
      final message = Messages.fromJson(data);
      final messageModel = MessageModel.fromJson(data);
      print(jsonEncode(messageModel));
      //handleIncomingMessage(message, messageModel);
    });
  }

  void listenDriverTypling() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('typingUser');

    socket.on('typingUser', (data) {
      if (data["userId"] == _homeController.groupId.value) {
        isTyping.value = data["isTyping"] ?? false;
        typingMsg.value = data["message"] ?? "";
      }
    });
  }

  void handleIncomingMessage(Messages message, MessageModel messageModel) {
    final homeController = Get.find<HomeController>();
    // 1️⃣ If message belongs to current open chat → add to messages
    if (message.userProfileId == homeController.groupId.value) {
      messages.insert(0, message);

      // Scroll handling
      if (!isAtBottom.value) {
        showScrollToBottomButton.value = true;
        scrollButtonTitle.value = "New Message";
      }
    }
    if (Get.isRegistered<ChannelController>()) {
      Get.find<ChannelController>().handleReceiveMessage(messageModel);
    }
  }

  void updateLastMessage({
    required String userProfileId,
    required Messages message,
  }) {
    //final list = overview.value.userChannels;
    // if (list == null) return;

    // final updated = list.map((channel) {
    //   if (channel.userProfileId == userProfileId) {
    //     return channel.copyWith(
    //       sentMessageCount: 0,
    //       lastMessage: message,
    //     );
    //   }
    //   return channel;
    // }).toList();

    // overview.update((o) {
    //   o?.userChannels = updated;
    // });
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    scrollController.dispose();
    msgInputController.dispose();
    super.onClose();
  }
}
