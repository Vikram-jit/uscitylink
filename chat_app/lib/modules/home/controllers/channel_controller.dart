import 'dart:async';

import 'package:chat_app/core/controller/global_loader_controller.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/models/channel_model.dart';
import 'package:chat_app/modules/home/models/message_model.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelController extends GetxController {
  var currentTab = 0.obs; // 0 = Messages, 1 = Files, 2 = Pins
  var isLoading = false.obs;
  var isLoadingM = false.obs;
  var isLoadingDrivers = false.obs;

  var errorText = "".obs;
  final selectedDrivers = <UserProfileModel>[].obs;

  final RxMap<String, bool> typingUsers = <String, bool>{}.obs;

  RxList<ChannelModel> channels = <ChannelModel>[].obs;
  RxList<UserChannels> channelMembers = <UserChannels>[].obs;

  RxList<UserProfileModel> drivers = <UserProfileModel>[].obs;

  final loader = Get.find<GlobalLoaderController>();

  RxString searchText = "".obs;
  Timer? _debounce;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;
  int totalPages = 0;
  final isLoadingFirst = false.obs;
  final isLoadingMore = false.obs;
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

  void onSearch(String value) {
    searchText.value = value;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      getChannelMembers(page: 1, search: value);
    });
  }

  Future<void> handleChannelCreate(String name, String desc) async {
    if (name.trim().isEmpty) {
      AppSnackbar.error("Channel name is required");

      return;
    }
    loader.show();

    try {
      final res = await ChannelService().postChannel(
        name: name,
        description: desc,
      );

      if (res.status) {
        // ✅ close dialog
        Get.back();
        loader.hide();
        getChannels();
        AppSnackbar.success(res.message);
      } else {
        loader.hide();
        AppSnackbar.error(res.message);
      }
    } catch (e) {
      loader.hide();
      AppSnackbar.error("Something went wrong");

      print("Create channel error: $e");
    }
  }

  Future<void> handleDriverAddToChannel() async {
    if (selectedDrivers.isEmpty) {
      AppSnackbar.error("Select atleast one driver.");

      return;
    }
    loader.show();

    try {
      final res = await ChannelService().addMemberToChannel(
        ids: [...selectedDrivers.map((e) => e.id!)],
      );

      if (res.status) {
        // ✅ close dialog
        Get.back();
        loader.hide();
        getChannelMembers();
        AppSnackbar.success(res.message);
      } else {
        loader.hide();
        AppSnackbar.error(res.message);
      }
    } catch (e) {
      loader.hide();
      AppSnackbar.error("Something went wrong");

      print("Create channel error: $e");
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

  void replaceChannelMember(UserChannels user) {
    int index = channelMembers.indexWhere(
      (channel) =>
          channel.channelId == user.channelId &&
          channel.userProfileId == user.userProfileId,
    );

    if (index != -1) {
      // remove from current position
      channelMembers.removeAt(index);
    }

    // add at top
    channelMembers.insert(0, user);
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
    isLoadingFirst.value = false;
    isLoadingMore.value = false;
    totalItems = 0;
    totalPages = 0;
    channelMembers.clear();
    print('Pagination reset');
  }

  Future<void> getChannels() async {
    try {
      loader.show();

      final res = await ChannelService().channels();

      if (res.status) {
        channels.value = res.data!;
        loader.hide();
      } else {
        loader.hide();
        errorText.value = res.message;
      }
    } catch (e) {
      loader.hide();
      errorText.value = "Error: $e";
    } finally {
      loader.hide();
    }
  }

  Future<void> getDriverss() async {
    try {
      isLoadingDrivers.value = true;
      final res = await ChannelService().channelMemmbersWithoutAdd();

      if (res.status) {
        drivers.value = res.data ?? [];
      } else {
        errorText.value = res.message;
      }
      isLoadingDrivers.value = false;
    } catch (e) {
      errorText.value = "Error: $e";
      isLoadingDrivers.value = false;
    } finally {
      isLoadingDrivers.value = false;
    }
  }

  attachScroll() {
    scrollController.addListener(_onScroll);
  }

  Future<void> getChannelMembers({int page = 1, String search = ""}) async {
    if (isLoadingM.value) return;

    if (page == 1) {
      isLoadingFirst.value = true;
      resetPagination();
    } else {
      isLoadingMore.value = true;
    }

    try {
      isLoadingM.value = true;
      currentPage.value = page;

      final res = await ChannelService().channelMemmbers(
        page,
        Get.currentRoute == AppRoutes.driverChat ? 30 : 10,
        search,
        true,
      );

      if (res.status) {
        final newItems = res.data?.userChannels ?? [];
        final pagination = res.data?.pagination;

        if (page == 1) {
          // First page → replace
          channelMembers.assignAll(newItems);
        } else {
          // Next pages → append
          channelMembers.addAll(newItems);
        }

        hasMore.value =
            (pagination?.currentPage ?? 1) < (pagination?.totalPages ?? 1);
        totalItems = pagination?.total ?? 0;
        totalPages = pagination?.totalPages ?? 0;
      }
    } catch (e) {
      print(e);
    } finally {
      isLoadingM.value = false;
      isLoadingFirst.value = false;
      isLoadingMore.value = false;
    }
  }

  // Method to manually refresh
  Future<void> refreshData() async {
    resetPagination();
    await getChannelMembers(page: 1);
  }

  // Method to load next page
  Future<void> loadNextPage() async {
    if (!isLoading.value && hasMore.value) {
      await getChannelMembers(page: currentPage.value + 1);
    }
  }

  void handleUpdateUnreadCount(data) {
    final profileId = data["userId"] ?? "";

    int index = channelMembers.indexWhere(
      (channel) => channel.userProfileId == profileId,
    );

    if (index != -1) {
      channelMembers[index].unreadCount = 0;

      // Notify GetX that the list has changed
      channelMembers.refresh();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
