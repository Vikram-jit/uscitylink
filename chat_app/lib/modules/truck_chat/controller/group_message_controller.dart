import 'dart:async';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/models/group_message_response_model.dart';
import 'package:chat_app/models/group_response_model.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/media_gallery.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/modules/home/services/file_upload_service.dart';
import 'package:chat_app/modules/home/services/message_service.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/services/group_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupMessageController extends GetxController {
  var currentTab = 0.obs;
  final showDetails = false.obs;
  final messages = <Messages>[].obs;
  final isLoading = false.obs;
  final memmbers = <GroupMembers>[].obs;
  final senderId = "".obs;
  final group = GroupModel().obs;
  final selectMessageReply = Rxn<Messages>();
  final selectTemplateUrl = Rxn<Template>();

  PlatformFile? pendingFile;

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
  MessageController _messageController = Get.find<MessageController>();

  final msgInputController = TextEditingController();
  final msgText = "".obs;

  final typingMsg = "".obs;
  final isTyping = false.obs;

  final isTypingStaff = false.obs;
  Timer? _typingTimer;

  final isUpdatingGroup = false.obs;
  final isDeletingGroup = false.obs;

  @override
  void onInit() {
    super.onInit();
    listenIncomingMessages();
    listenDriverTypling();
    scrollController.addListener(() => _onScroll());
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
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 50 &&
        !isLoading.value &&
        hasMore.value) {
      loadMore(
        _homeController.groupId.value,
        currentTab.value == 2 ? "1" : "0",
      );
    }
  }

  Future<void> loadMore(String userId, String pinMessage) async {
    if (!hasMore.value || isLoading.value) return;

    currentPage.value++;

    await _fetch(userId, currentPage.value, pinMessage);
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

  /// Convenience: load more messages for the currently open group
  Future<void> loadMoreForCurrentGroup(String pinMessage) async {
    final id = _homeController.groupId.value;
    if (id.isEmpty) return;
    await loadMore(id, pinMessage);
  }

  void switchTab(int index, MediaGallerySource source) {
    currentTab.value = index;
    // reset pagination
    currentPage.value = 1;
    hasMore.value = true;

    switch (index) {
      case 0:
        messages.clear();
        _messageController.messagesMedia.clear();
        loadMessages(_homeController.groupId.value, 1, "0");
        break;
      case 1:
        _messageController.media.clear();
        _messageController.fetchMedia(
          source == MediaGallerySource.channel
              ? _homeController.driverId.value
              : _homeController.groupId.value,
          1,
          source,
        );
        break;
      case 2:
        messages.clear();
        loadMessages(_homeController.groupId.value, 1, "1");
        break;
      default:
        messages.clear();
        loadMessages(_homeController.groupId.value, 1, "0");
    }
  }

  void toggleDetails() {
    showDetails.value = !showDetails.value;
  }

  clearChat() {
    currentPage.value = 1;
    showDetails.value = false;
    memmbers.clear();
    senderId.value = "";
    group.value = GroupModel();
    messages.clear();
    totalItems = 0;
    totalPages = 1;
    hasMore.value = true;
  }

  Future<void> loadMessages(String groupId, int page, String pinMessage) async {
    try {
      isLoading.value = true;
      currentPage.value = page;

      if (Get.isRegistered<MessageController>()) {
        _messageController.media.clear();
        _messageController.messagesMedia.clear();
      }
      final res = await MessageService().getGroupMessages(
        groupId,
        page,
        pinMessage,
      );

      if (res.status) {
        memmbers.value = res.data?.members ?? [];
        senderId.value = res.data?.senderId ?? "";
        group.value = res.data?.group ?? GroupModel();
        final mediaMessages =
            res.data?.messages ??
            [].where((m) => m.url != null && m.url!.isNotEmpty).toList();
        if (Get.isRegistered<MessageController>()) {
          _messageController.messagesMedia.addAll(
            mediaMessages as List<Messages>,
          );
        }
        messages.assignAll(res.data?.messages ?? []);
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

  Future<void> _fetch(String userId, int page, String pinMessage) async {
    try {
      isLoading.value = true;

      final res = await MessageService().getGroupMessages(
        userId,
        page,
        pinMessage,
      );
      if (res.status) {
        final pagination = res.data?.pagination;
        final mediaMessages =
            res.data?.messages ??
            [].where((m) => m.url != null && m.url!.isNotEmpty).toList();
        if (Get.isRegistered<MessageController>()) {
          _messageController.messagesMedia.addAll(
            mediaMessages as List<Messages>,
          );
        }

        messages.addAll(res.data?.messages ?? []);

        hasMore.value =
            (pagination?.currentPage ?? 1) < (pagination?.totalPages ?? 1);

        totalPages = pagination?.totalPages ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
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

  Future<void> sendMessage({
    required String body,
    String? replyMessageId,
    String? url,
    String? thumbnail,
    String? reply_message_id,
  }) async {
    String userIds = memmbers
        .where((e) => e.status == "active")
        .map((e) => e.userProfileId) // or e.id depending on your model
        .join(",");

    if (pendingFile != null) {
      final resFile = await FileUploadService().uploadForUserMessage(
        file: pendingFile!,
        userId: '',
      );
      if (!resFile.status || resFile.key == null) {
        AppSnackbar.error('File upload failed, please try again.');
        return;
      }
      url = resFile.key;
    }
    SocketService().emit('send_message_to_user_by_group', {
      "userId": userIds,
      "groupId": group.value.id,
      "body": body,
      "direction": 'S',
      "url": url,
      "reply_message_id": replyMessageId,
    });
    msgInputController.clear();
  }

  Future<bool> sendFile() async {
    String url = "";
    String userIds = memmbers
        .where((e) => e.status == "active")
        .map((e) => e.userProfileId) // or e.id depending on your model
        .join(",");

    if (pendingFile != null) {
      final resFile = await FileUploadService().uploadForUserMessage(
        file: pendingFile!,
        userId: userIds,
        groupId: group.value.id ?? '',
      );
      if (!resFile.status || resFile.key == null) {
        AppSnackbar.error('File upload failed, please try again.');
        return false;
      }
      url = resFile.key!;
    }
    SocketService().emit('send_message_to_user_by_group', {
      "userId": userIds,
      "groupId": group.value.id,
      "body": msgInputController.text.trim(),
      "direction": 'S',
      "url": url,
    });
    pendingFile = null;
    msgInputController.clear();
    return true;
  }

  void listenIncomingMessages() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('receive_message_group_truck');
    socket.off('update_url_status_truck_group');
    socket.off('new_message_count_update_staff');

    // New incoming message for truck group
    socket.on('receive_message_group_truck', (data) {
      final msg = Messages.fromJson(data);
      final msgModel = MessageModel.fromJson(data);
      final currentGroupId = _homeController.groupId.value;

      // Ignore if not for currently open group
      if (msgModel.groupId != currentGroupId) {
        return;
      }

      // Deduplicate and prepend (newest first)
      final exists = messages.any((m) => m.id != null && m.id == msg.id);
      if (!exists) {
        messages.insert(0, msg);
      }
    });

    // Update upload status for media message
    socket.on('update_url_status_truck_group', (data) {
      final messageId = data['messageId']?.toString();
      final status = data['status'];
      if (messageId == null) return;

      final index = messages.indexWhere(
        (m) => m.id != null && m.id == messageId,
      );
      if (index != -1) {
        messages[index].urlUploadType = status?.toString();
        messages.refresh();
      }
    });

    // New message count / last message updates
    socket.on('new_message_count_update_staff', (data) {
      try {
        final msgModel = MessageModel.fromJson(data['message'] ?? {});
        final groupId = msgModel.groupId;
        if (groupId == null) return;

        final currentId = _homeController.groupId.value;
        final socketSvc = SocketService();

        // If this is the currently open group -> reset count on server and in list
        if (groupId == currentId) {
          socketSvc.emit('staff_open_truck__message_count', {
            'groupId': groupId,
            'count': 0,
          });

          if (Get.isRegistered<GroupController>()) {
            final gc = Get.find<GroupController>();
            final updated = gc.groups.map((g) {
              if (g.id == groupId) {
                g.messageCount = 0;
              }
              return g;
            }).toList();
            gc.groups.assignAll(updated);
          }
          return;
        }

        // Otherwise update lastMessage + increment messageCount
        if (Get.isRegistered<GroupController>()) {
          final gc = Get.find<GroupController>();
          final updated = gc.groups.map((g) {
            if (g.id == groupId) {
              g.lastMessage = msgModel;
              g.messageCount = (g.messageCount ?? 0) + 1;
            }
            return g;
          }).toList();
          gc.groups.assignAll(updated);
        }
      } catch (e) {
        errorText.value = "Socket handle error: $e";
      }
    });
  }

  void listenDriverTypling() {
    final socket = SocketService().socket;
    if (socket == null) return;

    socket.off('typingUser');
    socket.off('typingUserWeb');

    // Existing typing (direct messages)
    socket.on('typingUser', (data) {
      if (data["userId"] == _homeController.driverId.value) {
        isTyping.value = data["isTyping"] ?? false;
        typingMsg.value = data["message"] ?? "";
      }
    });

    // New typing event for truck group (web)
    socket.on('typingUserWeb', (data) {
      final bool typing = data['isTyping'] ?? false;
      final String? userId = data['userId'];
      final String message = data['message'] ?? "";

      // Only react if this user is a member of the current group
      if (userId != null &&
          memmbers.isNotEmpty &&
          !memmbers.any(
            (m) =>
                m.userProfileId == userId ||
                m.userProfile?.id == userId ||
                m.userProfile?.user?.id == userId,
          )) {
        return;
      }

      isTyping.value = typing;
      typingMsg.value = message;

      if (Get.isRegistered<ChannelController>()) {
        Get.find<ChannelController>().handelUserTyping(data);
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

  Future<bool> updateCurrentGroup({
    required String name,
    required String description,
  }) async {
    if (group.value.id == null || isUpdatingGroup.value) return false;
    try {
      isUpdatingGroup.value = true;
      final res = await GroupService().updateGroup(
        groupId: group.value.id!,
        name: name,
        description: description,
      );
      if (res.status) {
        group.update((g) {
          g?.name = name;
          g?.description = description;
        });
        return true;
      } else {
        errorText.value = res.message;
        return false;
      }
    } finally {
      isUpdatingGroup.value = false;
    }
  }

  Future<bool> deleteCurrentGroup() async {
    if (group.value.id == null || isDeletingGroup.value) return false;
    try {
      isDeletingGroup.value = true;
      final res = await GroupService().removeGroup(group.value.id!);
      if (res.status) {
        clearChat();
        return true;
      } else {
        errorText.value = res.message;
        return false;
      }
    } finally {
      isDeletingGroup.value = false;
    }
  }
}
