import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:chat_app/core/controller/global_loader_controller.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';

import 'package:chat_app/core/network/dio_client.dart';
import 'package:chat_app/core/services/socket_service.dart';
import 'package:chat_app/modules/home/services/channel_service.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';

class BroadcastFormController extends GetxController {
  // ================= STATE =================
  final mode = "specific".obs;
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
  Rx<PlatformFile?> pendingFile = Rx<PlatformFile?>(null);
  int page = 1;
  final int pageSize = 30;

  final ScrollController scrollController = ScrollController();

  GlobalLoaderController globalLoader = Get.find<GlobalLoaderController>();
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    scrollController.addListener(_onScroll);
    ever(search, (_) => _debouncedSearch());
  }

  // ================= Wasm-Safe File Picker =================
  void pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      pendingFile.value = result.files.first;
    } on PlatformException catch (e) {
      AppSnackbar.error('Unsupported operation: $e');
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
    // // 1. Create a hidden HTML input element
    // final web.HTMLInputElement input =
    //     web.document.createElement('input') as web.HTMLInputElement;
    // input.type = 'file';
    // input.accept = 'image/*,application/pdf,.doc,.docx';

    // input.onChange.listen((event) {
    //   final files = input.files;
    //   if (files != null && files.length > 0) {
    //     final file = files.item(0)!;
    //     final reader = web.FileReader();

    //     pickedFileName.value = file.name;

    //     // 2. Read the file into memory
    //     reader.readAsArrayBuffer(file);
    //     reader.onLoadEnd.listen((e) {
    //       final JSAny? result = reader.result;
    //       if (result != null) {
    //         try {
    //           // 3. Cast to JS Interop type
    //           final JSArrayBuffer buffer = result as JSArrayBuffer;

    //           // 4. Convert using the .toDart GETTER (No parentheses)
    //           final ByteBuffer dartBuffer = buffer.toDart;

    //           // 5. Assign as Uint8List
    //           pickedBytes.value = dartBuffer.asUint8List();

    //           print("File loaded: ${pickedFileName.value}");
    //         } catch (err) {
    //           print("Conversion error: $err");
    //         }
    //       }
    //     });
    //   }
    // });

    // // 6. Trigger the system dialog
    // input.click();
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage() async {
    try {
      if (messageController.text.trim().isEmpty) return;
      print(isAllSelected.value);
      if (!isAllSelected.value && selectedUsers.isEmpty) {
        AppSnackbar.error("Select at least one user");
        return;
      }

      globalLoader.show();

      final userIds = isAllSelected.value
          ? users.map((u) => u.userProfile?.id).toList()
          : selectedUsers.map((u) => u.userProfile?.id).toList();
      print(userIds);
      // ================= FILE UPLOAD LOGIC =================
      if (pendingFile.value != null) {
        FormData formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            pendingFile.value!.bytes!,
            filename: pendingFile.value!.name,
          ),
          "isMultiple": "true",
          "userId": jsonEncode(userIds),
          "source": "message",
          // Check extension from filename
          "type": _isImage(pendingFile.value!.name) ? "media" : "doc",
        });

        final res = await DioClient().dio.post(
          "/message/fileUploadWeb",
          data: formData,
        );
        final data = res.data;

        SocketService().emit("broadcast_to_user", {
          "body": messageController.text.trim(),
          "userId": jsonEncode(userIds),
          "direction": "S",
          "url": data["data"]["key"],
          "thumbnail": data["data"]["thumbnail"],
          "url_upload_type": "server",
        });
      } else {
        // Text-only broadcast
        SocketService().emit("broadcast_to_user", {
          "body": messageController.text.trim(),
          "userId": jsonEncode(userIds),
          "direction": "S",
          if (url.value.isNotEmpty) "url": url.value,
          if (url.value.isNotEmpty) "url_upload_type": "server",
        });
      }

      _finishAndReset();

      AppSnackbar.success("Message sent successfully");
    } catch (e) {
      globalLoader.show();
      AppSnackbar.error("Failed to send message: $e");
    }
  }

  void _finishAndReset() {
    globalLoader.hide();
    messageController.clear();

    pickedBytes.value = null;
    pickedFileName.value = "";
    selectedUsers.clear();
    isAllSelected.value = false;
    pendingFile.value = null;
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
    pendingFile.value = null;
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
