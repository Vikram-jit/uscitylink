import 'dart:async';
import 'dart:convert';
import 'dart:js_interop'; // Mandatory for .toDart getter
import 'dart:typed_data';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web; // Modern 2026 standard for Web/Wasm

import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';

class BroadcastFormController extends GetxController {
  // ================= STATE =================
  final mode = "specific".obs;
  final message = "".obs;
  final url = "".obs;
  final messageController = TextEditingController();

  // File State (Using bytes and names for Web compatibility)
  final pickedBytes = Rx<Uint8List?>(null);
  final pickedFileName = "".obs;

  final users = <UserChannels>[].obs;
  final selectedUsers = <UserChannels>[].obs;
  final isAllSelected = false.obs;

  final isLoading = false.obs;
  final hasMore = true.obs;
  final search = "".obs;

  int page = 1;
  final int pageSize = 30;

  final ScrollController scrollController = ScrollController();
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    scrollController.addListener(_onScroll);
    ever(search, (_) => _debouncedSearch());
  }

  // ================= Wasm-Safe File Picker =================
  void pickFile() {
    // 1. Create a hidden HTML input element
    final web.HTMLInputElement input =
        web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*,application/pdf,.doc,.docx';

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        final reader = web.FileReader();

        pickedFileName.value = file.name;

        // 2. Read the file into memory
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final JSAny? result = reader.result;
          if (result != null) {
            try {
              // 3. Cast to JS Interop type
              final JSArrayBuffer buffer = result as JSArrayBuffer;

              // 4. Convert using the .toDart GETTER (No parentheses)
              final ByteBuffer dartBuffer = buffer.toDart;

              // 5. Assign as Uint8List
              pickedBytes.value = dartBuffer.asUint8List();

              print("File loaded: ${pickedFileName.value}");
            } catch (err) {
              print("Conversion error: $err");
            }
          }
        });
      }
    });

    // 6. Trigger the system dialog
    input.click();
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage() async {
    try {
      if (message.value.trim().isEmpty && pickedBytes.value == null) return;

      if (!isAllSelected.value && selectedUsers.isEmpty) {
        AppSnackbar.error("Select at least one user");
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final userIds = isAllSelected.value
          ? []
          : selectedUsers.map((u) => u.userProfile?.id).toList();

      // ================= FILE UPLOAD LOGIC =================
      if (pickedBytes.value != null) {
        FormData formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            pickedBytes.value!,
            filename: pickedFileName.value,
          ),
          "isMultiple": "true",
          "userId": jsonEncode(userIds),
          "source": "message",
          // Check extension from filename
          "type": _isImage(pickedFileName.value) ? "media" : "doc",
        });

        final res = await DioClient().dio.post(
          "/message/fileUploadWeb",
          data: formData,
        );
        final data = res.data;

        SocketService().emit("broadcast_to_user", {
          "body": message.value,
          "userId": jsonEncode(userIds),
          "direction": "S",
          "url": data["data"]["key"],
          "thumbnail": data["data"]["thumbnail"],
          "url_upload_type": "server",
        });
      } else {
        // Text-only broadcast
        SocketService().emit("broadcast_to_user", {
          "body": message.value,
          "userId": jsonEncode(userIds),
          "direction": "S",
          if (url.value.isNotEmpty) "url": url.value,
          if (url.value.isNotEmpty) "url_upload_type": "server",
        });
      }

      _finishAndReset();
      AppSnackbar.success("Message sent successfully");
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.error("Failed to send message: $e");
    }
  }

  void _finishAndReset() {
    if (Get.isDialogOpen ?? false) Get.back();
    messageController.clear();
    message.value = "";
    pickedBytes.value = null;
    pickedFileName.value = "";
    selectedUsers.clear();
    isAllSelected.value = false;

    try {
      Get.find<BroadcastController>().init();
    } catch (e) {
      print("Refresh error: $e");
    }
  }

  bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }

  // ================= LIST LOGIC =================
  void setSearch(String value) => search.value = value;

  void _debouncedSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      resetUsers();
      fetchUsers();
    });
  }

  Future<void> fetchUsers() async {
    if (isLoading.value || !hasMore.value) return;
    try {
      isLoading.value = true;
      final res = await ChannelService().channelMemmbers(
        page,
        pageSize,
        search.value,
        false,
      );
      if (res.status && res.data != null) {
        final newUsers = res.data!.userChannels ?? [];
        users.addAll(newUsers);
        hasMore.value = newUsers.length == pageSize;
        page++;
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      print("User fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 100 &&
        !isLoading.value &&
        hasMore.value) {
      fetchUsers();
    }
  }

  void resetUsers() {
    users.clear();
    page = 1;
    hasMore.value = true;
  }

  void changeMode(String value) {
    mode.value = value;
    if (value == "all") {
      isAllSelected.value = true;
      selectedUsers.clear();
    } else {
      isAllSelected.value = false;
    }
  }

  void toggleUser(UserChannels user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
