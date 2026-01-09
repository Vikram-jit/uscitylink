import 'dart:convert';

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  var isLoading = false.obs;
  var isLoadingM = false.obs;
  var errorText = "".obs;

  final RxMap<String, bool> typingUsers = <String, bool>{}.obs;

  RxList<ChannelModel> channels = <ChannelModel>[].obs;
  RxList<UserChannels> channelMembers = <UserChannels>[].obs;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;
  int totalPages = 0;
  final SocketService _socketService = SocketService();

  final hasMore = true.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    getChannels();
  }

  @override
  void onReady() {
    super.onReady();

    if (Get.currentRoute == AppRoutes.driverChat) {
      resetPagination();
      getChannelMembers(page: 1);

      scrollController.removeListener(_onScroll);
      scrollController.addListener(_onScroll);
    }
  }

  void handleDriverOnlineEvent(dynamic data) {
    final bool isOnline = data['isOnline'] ?? false;
    final Map<String, dynamic> driverJson = data['driver'];

    final int existingIndex = channelMembers.indexWhere(
      (d) => d.userProfile?.id == driverJson["profiles"][0]['id']?.toString(),
    );

    if (existingIndex != -1) {
      if (channelMembers[existingIndex].userProfile != null) {
        channelMembers[existingIndex].userProfile!.isOnline = isOnline;
      }

      channelMembers.refresh();
    }
  }

  void handelUserTyping(dynamic data) {
    final String userId = data['userId'];
    final bool isTyping = data['isTyping'] ?? false;

    setTyping(userId, isTyping);
  }

  void setTyping(String userId, bool isTyping) {
    typingUsers[userId] = isTyping;

    // 🔥 Force refresh (IMPORTANT)
    typingUsers.refresh();
  }

  bool isUserTyping(String userId) {
    return typingUsers[userId] ?? false;
  }

  void handleReceiveMessage(MessageModel message) {
    final int existingIndex = channelMembers.indexWhere(
      (d) => d.userProfile?.id == message.userProfileId,
    );

    if (existingIndex == -1) return;

    if (channelMembers[existingIndex].userProfile != null) {
      channelMembers[existingIndex].lastMessage = message;
    }

    channelMembers.refresh();
  }

  void incrementUnreadCountByProfileId(String profileId) {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (profileId == homeController.driverId.value) return;

      final int existingIndex = channelMembers.indexWhere(
        (d) => d.userProfile?.id == profileId,
      );

      if (existingIndex == -1) return;

      if (channelMembers[existingIndex].userProfile != null) {
        channelMembers[existingIndex].unreadCount =
            (channelMembers[existingIndex].unreadCount ?? 0) + 1;
      }

      channelMembers.refresh();
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 80 &&
        !isLoading.value &&
        hasMore.value) {
      // Calculate next page
      final nextPage = currentPage.value + 1;
      getChannelMembers(page: nextPage);
    }
  }

  void resetPagination() {
    isLoadingM.value = false;
    currentPage.value = 1;
    hasMore.value = true;
    totalItems = 0;
    totalPages = 0;
    channelMembers.clear();
    print('Pagination reset');
  }

  Future<void> getChannels() async {
    try {
      isLoading.value = true;

      final res = await ChannelService().channels();

      if (res.status) {
        channels.value = res.data!;
        isLoading.value = false;
      } else {
        isLoading.value = false;
        errorText.value = res.message;
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorText.value = "Error: $e";
    } finally {
      isLoading.value = false;
    }
  }

  attachScroll() {
    scrollController.addListener(_onScroll);
  }

  Future<void> getChannelMembers({int page = 1}) async {
    // Prevent multiple simultaneous calls
    if (isLoadingM.value) return;

    // Reset for first page
    if (page == 1) {
      resetPagination();
    }

    // Stop if no more pages
    if (!hasMore.value) {
      print('No more pages to load');
      return;
    }

    try {
      isLoadingM.value = true;
      currentPage.value = page;
      print('Loading page $page...');
      update(); // Force GetBuilder to rebuild

      final res = await ChannelService().channelMemmbers(
        page,
        Get.currentRoute == AppRoutes.driverChat ? 30 : 10,
      );

      if (res.status) {
        final newItems = res.data?.userChannels ?? [];
        final pagination = res.data?.pagination;

        print('API Response: ${newItems.length} items');

        if (pagination != null) {
          totalItems = pagination.total ?? 0;
          itemsPerPage = pagination.pageSize ?? 0;
          totalPages = pagination.totalPages ?? 0;

          print(
            'Pagination: Page $page/$totalPages, ' +
                'PageSize: $itemsPerPage, Total: $totalItems',
          );

          // Add new items
          if (page == 1) {
            channelMembers.assignAll(newItems);
          } else {
            channelMembers.addAll(newItems);
          }

          // Check if more pages exist
          hasMore.value = page < totalPages;

          print(
            'Current items: ${channelMembers.length}, ' +
                'Has more pages: ${hasMore.value}',
          );
        } else {
          // Fallback if no pagination
          if (page == 1) {
            channelMembers.assignAll(newItems);
          } else {
            channelMembers.addAll(newItems);
          }
          // Assume no more data if we got less than requested
          hasMore.value = newItems.length >= itemsPerPage;
        }

        // Notify UI
        update();
      } else {
        errorText.value = res.message;
        print('API Error: ${res.message}');
      }
    } catch (e) {
      errorText.value = "Error: $e";
      print('Exception: $e');
    } finally {
      isLoadingM.value = false;
      print('Loading complete');
    }
  }

  // Method to manually refresh
  Future<void> refreshData() async {
    print('Manual refresh triggered');
    resetPagination();
    await getChannelMembers(page: 1);
  }

  // Method to load next page
  Future<void> loadNextPage() async {
    if (!isLoading.value && hasMore.value) {
      await getChannelMembers(page: currentPage.value + 1);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
