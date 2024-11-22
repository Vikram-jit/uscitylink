import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DocumentController extends GetxController {
  // Reactive variables to manage UI state
  var isSaving = false.obs; // To indicate if the image is being saved
  var isDownloading = false.obs; // To indicate if the image is being downloaded
  var saveSuccess = false.obs;
  var errorMessage = ''.obs;

  // Function to save image to gallery
  Future<void> saveImageToGallery(String imageUrl) async {
    Utils.showLoader();
    // Show loader while saving
    isSaving.value = true;
    isDownloading.value = true; // Show downloading indicator

    // Request storage permission (for Android)
    PermissionStatus status = await Permission.storage.request();
    if (!status.isGranted) {
      Utils.hideLoader();
      errorMessage.value = "Permission Denied!";
      showErrorSnackBar("Permission Denied!"); // Show snack bar
      isSaving.value = false;
      isDownloading.value = false;
      return;
    }

    try {
      // Fetch the image from the URL as bytes
      final ByteData data =
          await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
      final Uint8List bytes = data.buffer.asUint8List();

      // Save the image to gallery
      final result = await ImageGallerySaver.saveImage(bytes);
      if (result['isSuccess']) {
        Utils.hideLoader();
        saveSuccess.value = true;
        showSuccessSnackBar(
            "Image Saved Successfully!"); // Show success snackbar
        errorMessage.value = ''; // Clear any previous errors
      } else {
        Utils.hideLoader();
        saveSuccess.value = false;
        errorMessage.value = 'Failed to Save Image!';
        showErrorSnackBar("Failed to Save Image!"); // Show error snackbar
      }
    } catch (e) {
      Utils.hideLoader();
      // Handle any errors during the saving process
      saveSuccess.value = false;
      errorMessage.value = 'Error saving image: $e';
      showErrorSnackBar("Error saving image: $e"); // Show error snackbar
    } finally {
      Utils.hideLoader();
      isSaving.value = false; // Set saving state to false when done
      isDownloading.value = false; // Set downloading state to false when done
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
      print(directory.path);
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
