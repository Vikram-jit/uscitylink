// controllers/forward_message_controller.dart

import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:get/get.dart';

class ForwardMessageController extends GetxController {
  ForwardMessageController();

  final users = <UserChannels>[].obs;
  final selectedUserIds = <String>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchText = ''.obs;
  final isTruckMode = false.obs;

  int _page = 1;
  static const int _limit = 12;

  @override
  void onInit() {
    super.onInit();
    // Debounce search
    debounce(
      searchText,
      (_) => _resetAndFetch(),
      time: const Duration(milliseconds: 300),
    );
    fetchUsers(refresh: true);
  }

  void _resetAndFetch() {
    _page = 1;
    hasMore.value = true;
    users.clear();
    fetchUsers();
  }

  void toggleTruckMode() {
    isTruckMode.value = !isTruckMode.value;
    if (!isTruckMode.value) searchText.value = '';
    _resetAndFetch();
  }

  void toggleUser(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  bool isSelected(String userId) => selectedUserIds.contains(userId);

  Future<void> fetchUsers({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      hasMore.value = true;
      users.clear();
    }

    if (!hasMore.value) return;

    _page == 1 ? isLoading.value = true : isLoadingMore.value = true;

    try {
      final res = await ChannelService().channelMemmbers(
        _page,
        _limit,
        searchText.value,
        true,
      );

      if (res.status && res.data != null) {
        final list = res.data!.userChannels ?? [];
        users.addAll(list);

        final pagination = res.data!.pagination;
        if (pagination != null) {
          hasMore.value = pagination.currentPage! < pagination.totalPages!;
        } else {
          hasMore.value = false;
        }
        _page++;
      }
    } catch (e) {
      AppSnackbar.error('Failed to load members');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void sendForward(Messages message) {
    if (selectedUserIds.isEmpty) return;

    SocketService().emit('FORWARD_MESSAGE_TO_DRIVERS', {
      "body": message.body,
      "userId": selectedUserIds,
      "direction": 'S',
      "url": message.url,
      "thumbnail": message.thumbnail,
      "url_upload_type": message.urlUploadType,
    });

    selectedUserIds.clear();
    Get.back();
  }

  void reset() {
    selectedUserIds.clear();
    searchText.value = '';
    isTruckMode.value = false;
    _resetAndFetch();
  }
}
