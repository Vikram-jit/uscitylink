import 'package:chat_app/models/group_response_model.dart' show GroupModel;
import 'package:chat_app/modules/truck_chat/services/group_service.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupController extends GetxController {
  var isLoading = false.obs;
  var errorText = "".obs;
  RxList<GroupModel> groups = <GroupModel>[].obs;

  RxInt currentPage = 1.obs;
  int itemsPerPage = 10;
  int totalItems = 0;
  int totalPages = 0;

  final hasMore = true.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();

    if (Get.currentRoute == AppRoutes.truckChat &&
        groups.isEmpty &&
        !isLoading.value) {
      refreshData();
      getGroups(page: currentPage.value);
      scrollController.removeListener(_onScroll);
      scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 80 &&
        !isLoading.value &&
        hasMore.value) {
      // Calculate next page
      final nextPage = currentPage.value + 1;
      getGroups(page: nextPage);
    }
  }

  void resetPagination() {
    isLoading.value = false;
    currentPage.value = 1;
    hasMore.value = true;
    totalItems = 0;
    totalPages = 0;
    groups.clear();
    print('Pagination reset');
  }

  Future<void> getGroups({int page = 1}) async {
    // Prevent multiple simultaneous calls
    if (isLoading.value) return;

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
      isLoading.value = true;
      currentPage.value = page;
      print('Loading page $page...');
      update(); // Force GetBuilder to rebuild

      final res = await GroupService().groups(page, itemsPerPage, "truck");

      if (res.status) {
        final newItems = res.data?.data ?? [];
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
            groups.assignAll(newItems);
          } else {
            groups.addAll(newItems);
          }

          // Check if more pages exist
          hasMore.value = page < totalPages;

          print(
            'Current items: ${groups.length}, ' +
                'Has more pages: ${hasMore.value}',
          );
        } else {
          // Fallback if no pagination
          if (page == 1) {
            groups.assignAll(newItems);
          } else {
            groups.addAll(newItems);
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
      isLoading.value = false;
      print('Loading complete');
    }
  }

  // Method to manually refresh
  Future<void> refreshData() async {
    print('Manual refresh triggered');
    resetPagination();
    await getGroups(page: 1);
  }

  // Method to load next page
  Future<void> loadNextPage() async {
    if (!isLoading.value && hasMore.value) {
      await getGroups(page: currentPage.value + 1);
    }
  }
}
