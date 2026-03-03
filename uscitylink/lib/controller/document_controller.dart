import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DocumentController extends GetxController {
  var isSaving = false.obs;
  var isDownloading = false.obs;
  var saveSuccess = false.obs;
  var errorMessage = ''.obs;
  List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'flv',
    'webm',
    'mpeg',
    'mpg',
    'wmv'
  ];

  Future<bool> requestIOSGalleryPermission() async {
    if (!Platform.isIOS) return true;

    var status = await Permission.photos.status;
    print("Before request: $status");

    if (status.isGranted || status.isLimited) {
      return true;
    }

    // 🔥 This forces popup
    status = await Permission.photos.request();
    print("After request: $status");

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      print("Permission permanently denied");
      openAppSettings();
    }

    return false;
  }

  Future<void> saveImageToGallery(String imageUrl) async {
    isSaving.value = true;
    isDownloading.value = true;
    saveSuccess.value = false;

    try {
      bool allowed = await requestIOSGalleryPermission();
      if (!allowed) {
        showErrorSnackBar("Permission Denied");
        return;
      }

      String extension = imageUrl.split('.').last.toLowerCase();

      if (videoExtensions.contains(extension)) {
        final tempDir = await getTemporaryDirectory();
        final tempFilePath = '${tempDir.path}/temp_video.mp4';

        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode != 200) {
          throw Exception("Video download failed");
        }

        final file = File(tempFilePath);
        await file.writeAsBytes(response.bodyBytes);

        await Gal.putVideo(tempFilePath);
      } else {
        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode != 200) {
          throw Exception("Image download failed");
        }

        await Gal.putImageBytes(response.bodyBytes);
      }

      saveSuccess.value = true;
      showSuccessSnackBar("Saved Successfully!");
    } catch (e) {
      saveSuccess.value = false;
      errorMessage.value = 'Error saving: $e';
      showErrorSnackBar("Error saving file");
    } finally {
      isSaving.value = false;
      isDownloading.value = false;
    }
  }

// Save PDF to Local File System
  Future<void> savePdfToFileSystem(String pdfUrl) async {
    Utils.showLoader();
    isSaving.value = true;
    errorMessage.value = '';
    // Request permission to write to storage
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      Utils.hideLoader();
      errorMessage.value = "Permission Denied!";
      showErrorSnackBar("Permission Denied!");
      isSaving.value = false;
      return;
    }

    try {
      // Download the PDF file
      final file = await DefaultCacheManager().getSingleFile(pdfUrl);

      // Get the directory where we want to save the file
      final directory = await getApplicationSupportDirectory();

      final filePath = '${directory.path}/downloaded_document.pdf';

      // Save the PDF file to local storage
      await file.copy(filePath);

      saveSuccess.value = true;
      Utils.hideLoader();
      showSuccessSnackBar("PDF Saved Successfully!");
    } catch (e) {
      Utils.hideLoader();
      errorMessage.value = "Error saving PDF: $e";
      showErrorSnackBar("Error saving PDF: $e");
    } finally {
      Utils.hideLoader();
      isSaving.value = false;
    }
  }

  Future<void> downloadFile(file) async {
    try {
      Utils.showLoader();
      // Set download status to true and reset progress
      isDownloading.value = true;
      final now = DateTime.now();
      // Get the path where the file will be saved
      final directory = await getApplicationDocumentsDirectory();
      final folderPath = directory.path;
      final filePath =
          '$folderPath/${now}_myfile.pdf'; // Change filename as needed

      // Check if the folder exists, if not, create it
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // Make the HTTP request to fetch the file
      var response = await http.get(Uri.parse(file));

      if (response.statusCode == 200) {
        // File downloaded successfully, now save it
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Mark download complete
        isDownloading.value = false;
        Utils.hideLoader();
        showSuccessSnackBar('File downloaded and saved to local storage.');
      } else {
        Utils.hideLoader();
        throw Exception('Failed to download file');
      }
    } catch (e) {
      Utils.hideLoader();
      isDownloading.value = false;
      errorMessage.value = e.toString();
      showErrorSnackBar('Failed to download file: $e');
    }
  }

  // Helper to show success snackbar
  void showSuccessSnackBar(String message) {
    if (!Get.isSnackbarOpen) {
      // Check if snackbar is already open
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  // Helper to show error snackbar
  void showErrorSnackBar(String message) {
    if (!Get.isSnackbarOpen) {
      // Check if snackbar is already open
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
