import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/system_messages/system_message_model.dart';
import 'package:chat_app/modules/system_messages/system_message_service.dart';

class SystemMessageController extends GetxController {
  final _service = SystemMessageService();

  final messages = <SystemMessage>[].obs;
  final unreadMessages = <SystemMessage>[].obs;
  final staffUsers = <UserProfileModel>[].obs;

  final isLoading = false.obs;
  final hasMore = true.obs;
  final unreadCount = 0.obs;

  final search = ''.obs;
  final completedByFilter = ''.obs;
  final startDate = ''.obs;
  final endDate = ''.obs;

  int currentPage = 1;
  final int pageSize = 10;
  final ScrollController scrollController = ScrollController();

  Timer? _debounce;
  bool isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  @override
  void onReady() {
    super.onReady();
    if (!isInitialized) {
      isInitialized = true;
      init();
      _loadStaffUsers();
    }
  }

  void init() {
    reset();
    fetchMessages();
    fetchUnread();
  }

  void reset() {
    messages.clear();
    currentPage = 1;
    hasMore.value = true;
  }

  Future<void> fetchMessages() async {
    if (isLoading.value || !hasMore.value) return;
    try {
      isLoading.value = true;
      final res = await _service.getSystemMessages(
        currentPage,
        pageSize,
        search: search.value,
        completedBy: completedByFilter.value,
        startDate: startDate.value,
        endDate: endDate.value,
      );
      if (res.status && res.data != null) {
        messages.addAll(res.data!.messages);
        hasMore.value =
            (res.data!.pagination.currentPage ?? 0) <
            (res.data!.pagination.totalPages ?? 0);
        currentPage++;
      } else {
        hasMore.value = false;
      }
    } catch (_) {
      hasMore.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUnread() async {
    try {
      final res = await _service.getSystemUnreadMessages();
      if (res.status && res.data != null) {
        // Use value= for atomic replacement; assignAll() calls clear() first
        // which triggers an empty-list notification that can flicker the dialog.
        unreadMessages.value = res.data!.messages;
        unreadCount.value = unreadMessages.length;
      }
    } catch (_) {}
  }

  Future<void> _loadStaffUsers() async {
    try {
      final res = await _service.getStaffUsers();
      if (res.status && res.data != null) {
        staffUsers.assignAll(res.data!.users);
      }
    } catch (_) {}
  }

  Future<void> markComplete(String id) async {
    try {
      await _service.markComplete(id);
      await fetchUnread();
      _refreshList();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      await fetchUnread();
      _refreshList();
    } catch (_) {}
  }

  void _refreshList() {
    reset();
    fetchMessages();
  }

  void onSearchChange(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      search.value = value;
      _refreshList();
    });
  }

  void onCompletedByChange(String? value) {
    completedByFilter.value = value ?? '';
    _refreshList();
  }

  void onStartDateChange(String value) {
    startDate.value = value;
    _refreshList();
  }

  void onEndDateChange(String value) {
    endDate.value = value;
    _refreshList();
  }

  void clearFilters() {
    search.value = '';
    completedByFilter.value = '';
    startDate.value = '';
    endDate.value = '';
    _refreshList();
  }

  bool get hasActiveFilters =>
      search.value.isNotEmpty ||
      completedByFilter.value.isNotEmpty ||
      startDate.value.isNotEmpty ||
      endDate.value.isNotEmpty;

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100 &&
        !isLoading.value &&
        hasMore.value) {
      fetchMessages();
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
