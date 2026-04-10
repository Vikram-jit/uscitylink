import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/modules/broadcast_messages/broadcast_model.dart';
import 'package:chat_app/modules/broadcast_messages/broadcast_service.dart';

class BroadcastController extends GetxController {
  final BroadcastService _service = BroadcastService();

  final broadcasts = <BroadcastModel>[].obs;

  final isLoading = false.obs;
  final hasMore = true.obs;

  int currentPage = 1;
  final int pageSize = 10;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
  }

  bool isInitialized = false;

  @override
  void onReady() {
    super.onReady();

    if (!isInitialized) {
      isInitialized = true;
      init();
    }
  }

  void init() {
    reset();
    fetchBroadcasts();
  }

  void reset() {
    broadcasts.clear();
    currentPage = 1;
    hasMore.value = true;
  }

  Future<void> fetchBroadcasts() async {
    if (isLoading.value || !hasMore.value) return;

    try {
      print("🔥 API CALL PAGE: $currentPage");

      isLoading.value = true;

      final res = await _service.getBroadcastMessages(currentPage, pageSize);

      print("🔥 RESPONSE: ${res.status}");

      if (res.status && res.data != null) {
        final data = res.data!;

        broadcasts.addAll(data.messages);

        hasMore.value =
            data.pagination.currentPage! < data.pagination.totalPages!;

        currentPage++;
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      print("❌ Broadcast error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100 &&
        !isLoading.value &&
        hasMore.value) {
      fetchBroadcasts();
    }
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll); // 🔥 ADD THIS
    scrollController.dispose();
    super.onClose();
  }
}
