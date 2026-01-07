import 'dart:convert';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/home/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  final messages = <Messages>[].obs;
  final isLoading = false.obs;
  final userProfile = UserProfileModel().obs;

  RxString truckNumber = "".obs;
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

  @override
  void onInit() {
    super.onInit();
    listenIncomingMessages();
    scrollController.addListener(_onScroll);
    msgInputController.addListener(() {
      msgText.value = msgInputController.text.trim();
    });
  }

  void _onScroll() {
    // reverse list → top reached
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 40 &&
        !isLoading.value &&
        hasMore.value) {
      loadMore(_homeController.driverId.value);
    }
  }

  Future<void> loadMore(String userId) async {
    if (!hasMore.value) return;
    currentPage++;
    await _fetch(userId, currentPage.value);
  }

  void switchTab(int index) {
    currentTab.value = index;
  }

  Future<void> loadMessages(String userId, int page) async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
      isLoading.value = true;
      currentPage.value = page;

      final res = await MessageService().getMessages(
        userId,
        page,
        itemsPerPage,
      );

      if (res.status) {
        userProfile.value = res.data?.userProfile ?? UserProfileModel();
        truckNumber.value = res.data?.truckNumbers ?? "";
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

      final res = await MessageService().getMessages(
        userId,
        page,
        itemsPerPage,
      );
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
    required String userId,
    String? replyMessageId,
    String? url,
    String? thumbnail,
  }) {
    final payload = {
      "body": body,
      "userId": userId,
      "direction": "S",
      "url": url,
      "thumbnail": thumbnail,
      if (replyMessageId != null) "r_message_id": replyMessageId,
    };

    SocketService().emit("send_message_to_user", payload);
  }

  void listenIncomingMessages() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('receive_message_channel');

    socket.on('receive_message_channel', (data) {
      final message = Messages.fromJson(data);
      handleIncomingMessage(message);
    });
  }

  void handleIncomingMessage(Messages message) {
    final homeController = Get.find<HomeController>();
    // 1️⃣ If message belongs to current open chat → add to messages
    if (message.userProfileId == homeController.driverId.value) {
      messages.insert(0, message);

      // Scroll handling
      if (!isAtBottom.value) {
        showScrollToBottomButton.value = true;
        scrollButtonTitle.value = "New Message";
      }
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
    scrollController.dispose();
    msgInputController.dispose();
    super.onClose();
  }
}
