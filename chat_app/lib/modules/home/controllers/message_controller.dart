import 'dart:async';

import 'package:chat_app/core/helpers/media_file_helper.dart';
import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/media_model.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/home/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  final messages = <Messages>[].obs;
  final pinMessages = <Messages>[].obs;
  final messagesMedia = <Messages>[].obs;
  final media = <MediaModel>[].obs;
  final isLoading = false.obs;
  final userProfile = UserProfileModel().obs;
  final selectMessageReply = Rxn<Messages>();

  RxString truckNumber = "".obs;
  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;

  final isAtBottom = true.obs;
  final showScrollToBottomButton = false.obs;
  final scrollButtonTitle = "New Message".obs;

  var errorText = "".obs;

  final hasMore = true.obs;
  final hasMoreMedia = true.obs;
  int currentMediaPage = 1;

  int totalPages = 1;

  final ScrollController scrollController = ScrollController();
  final channelId = "".obs;

  HomeController _homeController = Get.find<HomeController>();

  final msgInputController = TextEditingController();
  final msgText = "".obs;

  final typingMsg = "".obs;
  final typingUserId = "".obs;
  final isTyping = false.obs;

  final isTypingStaff = false.obs;
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
    // reverse list → top reached
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 40 &&
        !isLoading.value &&
        hasMore.value) {
      loadMore(_homeController.driverId.value);
    }
  }

  Future<void> loadMoreMedia(String userId) async {
    if (!hasMoreMedia.value || isLoading.value) return;

    currentMediaPage++;
    await fetchMedia(userId, currentMediaPage);
  }

  void pinMessage(String messageId, String staffPin) {
    final newValue = staffPin == '0' ? '1' : '0';

    // 🔹 Emit to server
    SocketService().emit('pin_message', {
      "messageId": messageId,
      "value": newValue,
      "type": 'staff',
    });

    // 🔹 Update locally in messages list
    final index = messages.indexWhere((m) => m.id == messageId);

    if (index != -1) {
      messages[index].staffPin = newValue;

      // 👉 Important: refresh UI
      messages.refresh();
    }
  }

  void deleteMessage(String messageId) {
    // 🔹 Emit to server
    SocketService().emit('delete_message', {"messageId": messageId});

    // 🔹 Update locally in messages list
    final index = messages.indexWhere((m) => m.id == messageId);

    if (index != -1) {
      messages.removeAt(index);

      messages.refresh();
    }
  }

  Future<void> loadMore(String userId, {String? pinMessage}) async {
    if (!hasMore.value) return;
    currentPage++;
    await _fetch(userId, currentPage.value, pinMessage);
  }

  void switchTab(int index) {
    currentTab.value = index;
    // reset pagination
    currentPage.value = 1;
    hasMore.value = true;

    switch (index) {
      case 0:
        messages.clear();
        loadMessages(_homeController.driverId.value, 1);
        break;
      case 1:
        media.clear();
        fetchMedia(_homeController.driverId.value, 1);
        break;
      case 2:
        messages.clear();
        _fetch(_homeController.driverId.value, 1, "1");
        break;
      default:
        messages.clear();
        loadMessages(_homeController.driverId.value, 1);
    }
  }

  clearChat() {
    currentPage.value = 1;
    userProfile.value = UserProfileModel();
    truckNumber.value = "";

    messages.clear();
    messagesMedia.clear();

    totalItems = 0;
    totalPages = 1;
    hasMore.value = true;
    media.clear();
    hasMoreMedia.value = true;
  }

  Future<void> loadMessages(String userId, int page) async {
    try {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      isLoading.value = true;
      currentPage.value = page;

      // ✅ Reset everything for page 1
      if (page == 1) {
        messages.clear();
        messagesMedia.clear();
        media.clear();
        currentMediaPage = 1;
        hasMoreMedia.value = true;
        hasMore.value = true;
      }

      final res = await MessageService().getMessages(
        userId,
        page,
        itemsPerPage,
        "0",
      );

      if (res.status) {
        userProfile.value = res.data?.userProfile ?? UserProfileModel();
        truckNumber.value = res.data?.truckNumbers ?? "";

        final newMessages = res.data?.messages ?? [];

        messages.assignAll(newMessages);

        final mediaMessages = newMessages
            .where((m) => m.url != null && m.url!.isNotEmpty)
            .toList();

        messagesMedia.assignAll(mediaMessages);

        final pagination = res.data?.pagination;

        totalItems = pagination?.total ?? 0;
        totalPages = pagination?.totalPages ?? 1;

        hasMore.value =
            (pagination?.currentPage ?? 1) < (pagination?.totalPages ?? 1);
      } else {
        errorText.value = res.message;
      }
    } catch (e) {
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetch(String userId, int page, String? pinMessage) async {
    try {
      isLoading.value = true;

      final res = await MessageService().getMessages(
        userId,
        page,
        itemsPerPage,
        pinMessage,
      );

      if (res.status) {
        final newMessages = res.data?.messages ?? [];

        messages.addAll(newMessages);

        final mediaMessages = newMessages
            .where((m) => m.url != null && m.url!.isNotEmpty)
            .toList();

        messagesMedia.addAll(mediaMessages);

        final pagination = res.data?.pagination;

        hasMore.value =
            (pagination?.currentPage ?? 1) < (pagination?.totalPages ?? 1);

        totalPages = pagination?.totalPages ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMedia(String userId, int page) async {
    try {
      isLoading.value = true;

      final res = await MessageService().getMediaMessages(
        userId,
        page,
        itemsPerPage,
      );

      if (res.status) {
        final newMessages = res.data?.media ?? [];

        // media.addAll(newMessages);

        final mediaMessages = newMessages
            .where((m) => m.key != null && m.key!.isNotEmpty)
            .toList();

        media.addAll(mediaMessages);

        hasMoreMedia.value =
            (res.data?.page ?? 1) < (res.data?.totalPages ?? 1);

        totalPages = res.data?.totalPages ?? 1;
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

    msgInputController.clear();

    isTypingStaff.value = false;
    sendTypingStatus(false);
  }

  void listenIncomingMessages() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('receive_message_channel');

    socket.on('receive_message_channel', (data) {
      final message = Messages.fromJson(data);
      final messageModel = MessageModel.fromJson(data);
      handleIncomingMessage(message, messageModel);
    });
  }

  void listenDriverTypling() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('typingUserWeb');

    socket.on('typingUserWeb', (data) {
      typingUserId.value = data["userId"] ?? "";
      if (data["userId"] == _homeController.driverId.value) {
        isTyping.value = data["isTyping"] ?? false;
        typingMsg.value = data["message"] ?? "";
      }
    });
  }

  void handleIncomingMessage(Messages message, MessageModel messageModel) {
    final homeController = Get.find<HomeController>();

    if (message.userProfileId == homeController.driverId.value) {
      messages.insert(0, message);

      // ✅ add media automatically
      if (message.url != null && message.url!.isNotEmpty) {
        messagesMedia.insert(0, message);
      }

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
