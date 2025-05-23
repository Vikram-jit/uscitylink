import 'dart:io';

import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/widgets/file_picker_preview.dart';
import 'package:uscitylink/services/socket_service.dart';

class FilePickerController extends GetxController {
  final _apiService = NetworkApiService();
  SocketService socketService = Get.find<SocketService>();
  var filePath = ''.obs;
  var fileName = ''.obs;
  var fileType = ''.obs;
  var totalPages = 0.obs;
  var currentPage = 0.obs;
  RxString caption = ''.obs;

  Future<void> pickSingleFile(
      String channelId, String location, String? groupId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      // If the user selects a file
      String? path = result.files.single.path;
      String? extension = result.files.single.extension;
      String? name = result.files.single.name;
      // Update state
      filePath.value = path ?? '';
      fileType.value = extension ?? 'Unknown';
      fileName.value = name ?? "Unknown";
      // Navigate to the preview page
      Get.to(() => FilePickerPreview(
          channelId: channelId,
          type: "doc",
          location: location,
          groupId: groupId));
    } else {
      // If the user cancels or doesn't select a file
      filePath.value = 'No file selected';
    }
  }

  void updatePDFPage(int current, int total) {
    currentPage.value = current;
    totalPages.value = total;
  }

  // Function to pick multiple files (optional)
  Future<void> pickMultipleFiles() async {
    // Open the file picker dialog to select multiple files
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
      // Update the file path with multiple selected files (joining paths into a string)
      List<String> paths =
          result.files.map((file) => file.path ?? 'No file selected').toList();
      filePath.value = paths.join(', ');
    } else {
      // If no files are selected or user cancels
      filePath.value = 'No files selected';
    }
  }

  // Optional: Function to allow file selection based on specific extensions
  Future<void> pickFileWithExtension(String channelId, String location,
      String? groupId, String? source, String? userId) async {
    // Open the file picker dialog and allow only specific file types (e.g., PDFs)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      filePath.value = result.files.single.path ?? 'No file selected';
      fileType.value = result.files.single.extension ?? 'Unknown';
      fileName.value = result.files.single.name ?? "Unknown";

      Get.to(() => FilePickerPreview(
          channelId: channelId,
          type: "doc",
          location: location,
          groupId: groupId,
          userId: userId,
          source: source));
    } else {
      filePath.value = 'No file selected';
    }
  }

  void uploadFile(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      var file = File(filePath.value);
      var res = await _apiService.fileUpload(
        file,
        "${Constant.url}/message/fileUpload?groupId=$groupId&userId=$userId&source=$location",
        channelId,
        type,
      );
      if (res.status) {
        if (source == "staff") {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else if (location == "truck") {
            socketService.sendMessageToTruck(
                "", groupId!, caption.value, res.data.key!);
          } else {
            socketService.updateStaffActiveUserChat(channelId);
            socketService.sendMessageToUser(
                userId!, caption.value, res.data.key!);
          }
        } else {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else {
            socketService.updateActiveChannel(channelId);
            socketService.sendMessage(
                caption.value, res.data.key!, channelId, "", "", "server");
          }
        }

        Get.back();
        while (Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }
    } catch (e) {
      Utils.snackBar("File Upload Error", e.toString());
    }
  }

  void uploadVideo(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      var file = File(filePath.value);
      var res = await _apiService.fileUpload(
        file,
        "${Constant.url}/message/fileAwsUpload?groupId=$groupId&userId=$userId&source=$location",
        channelId,
        type,
      );
      if (res.status) {
        print("$source,$userId");
        if (source == "staff") {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else if (location == "truck") {
            socketService.sendMessageToTruck(
                "", groupId!, caption.value, res.data.key!);
          } else {
            socketService.updateStaffActiveUserChat(channelId);
            socketService.sendMessageToUser(
                userId!, caption.value, res.data.key!);
          }
        } else {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else {
            socketService.updateActiveChannel(channelId);
            socketService.sendMessage(
                caption.value, res.data.key!, channelId, "", "", "server");
          }
        }

        Get.back();
        while (Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }
    } catch (e) {
      Utils.snackBar("File Upload Error", e.toString());
    }
  }

  void setCaption(String newCaption) {
    caption.value = newCaption;
  }
}
