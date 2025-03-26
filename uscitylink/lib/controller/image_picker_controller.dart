import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/widgets/photo_preview.dart';
import 'package:uscitylink/views/widgets/photo_preview_multiple.dart';
import 'package:uscitylink/views/widgets/video_preview_screen.dart';
import 'package:video_compress/video_compress.dart';

class ImagePickerController extends GetxController {
  final _apiService = NetworkApiService();
  SocketService socketService = Get.find<SocketService>();

  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<List<File>> selectedImages = Rx<List<File>>([]);
  Rx<File?> selectedVideo = Rx<File?>(null);
  RxString caption = ''.obs;
  RxString selectedSource = ''.obs;

  final ImagePicker _picker = ImagePicker();
  var isLoading = false.obs; // Loading state for image
  Future<void> pickImageFromCamera(String channelId, String location,
      String? groupId, String? source, String? userId) async {
    try {
      isLoading.value = true;
      selectedSource.value = "camera";
      final XFile? image =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 25);
      if (image != null) {
        selectedImage.value = File(image.path);
        isLoading.value = false;
        Get.to(() => PhotoPreviewScreen(
              channelId: channelId,
              type: "media",
              location: location,
              groupId: groupId,
              source: source,
              userId: userId,
            ));
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }

  Future<void> recordVedioFromCamera(ImageSource imageSource, String channelId,
      String location, String? groupId, String? source, String? userId) async {
    try {
      // isLoading.value = true;
      selectedSource.value = "camera";
      final XFile? video = await _picker.pickVideo(source: imageSource);

      // print(video?.path);
      if (video != null) {
        var path = File(video.path);
        selectedVideo.value = path;
        isLoading.value = false;
        Get.to(() => VideoPreviewScreen(
              path: path,
              channelId: channelId,
              type: "media",
              location: location,
              groupId: groupId,
              source: source,
              userId: userId,
            ));
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }

  Future<void> pickImageFromGallery(String channelId, String location,
      String? groupId, String source, String userId) async {
    try {
      selectedSource.value = "gallery";
      isLoading.value = true;
      // final XFile? image = await _picker.pickMultiImage(
      //     source: ImageSource.gallery, imageQuality: 25);
      final List<XFile>? images =
          await _picker.pickMultiImage(imageQuality: 25);

      if (images != null) {
        for (var item in images) {
          selectedImages.value.add(File(item.path));
        }

        isLoading.value = false;
        Get.to(() => PhotoPreviewMultiple(
            channelId: channelId,
            type: "media",
            location: location,
            groupId: groupId,
            source: source,
            userId: userId));
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
  }

  void uploadFile(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      var res = await _apiService.fileUpload(
          selectedImage.value!,
          "${Constant.url}/message/fileUpload?groupId=$groupId&userId=$userId&source=$location",
          channelId,
          type);

      if (res.status) {
        if (source == "staff") {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else if (location == "truck") {
            socketService.sendMessageToTruck(
                "", groupId!, caption.value, res.data.key!);
          } else {
            socketService.sendMessageToUser(
                userId!, caption.value, res.data.key!);
          }
        } else {
          if (location == "group") {
            socketService.sendGroupMessage(
                groupId!, channelId, caption.value, res.data.key!);
          } else {
            socketService.sendMessage(caption.value, res.data.key!, channelId);
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

  void uploadMultiFile(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      var res = await _apiService.multiFileUpload(
          selectedImages.value!,
          "${Constant.url}/media/uploadFileQueue?groupId=$groupId&userId=$userId&source=$location&location=$type",
          channelId,
          caption.value);

      if (res.status) {
        Get.back();
        while (Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }
    } catch (e) {
      Utils.snackBar("File Upload Error", e.toString());
    }
  }

  void uploadFileVideo(String channelId, String type, String location,
      String? groupId, String? source, String? userId) async {
    try {
      Utils.showLoader();
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        selectedVideo.value!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // It's false by default
      );
      var res = await _apiService.videoUpload(
          File(mediaInfo!.path!),
          "${Constant.url}/message/fileAwsUpload?groupId=$groupId&userId=$userId&source=$location",
          channelId,
          type);

      if (res.status) {
        if (source == "staff") {
          if (location == "group") {
            socketService.sendGroupMessage(groupId!, channelId, caption.value,
                res.data.key!, res.data.thumbnail);
          } else if (location == "truck") {
            socketService.sendMessageToTruck(
                "", groupId!, caption.value, res.data.key!, res.data.thumbnail);
          } else {
            socketService.sendMessageToUser(
                userId!, caption.value, res.data.key!, res.data.thumbnail);
          }
        } else {
          if (location == "group") {
            socketService.sendGroupMessage(groupId!, channelId, caption.value,
                res.data.key!, res.data.thumbnail);
          } else {
            socketService.sendMessage(
                caption.value, res.data.key!, channelId, res.data.thumbnail);
          }
        }
        Utils.hideLoader();
        Get.back();
        while (Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }
    } catch (e) {
      Utils.hideLoader();
      Utils.snackBar("File Upload Error", e.toString());
    }
  }

  void clearSelectedImage() {
    selectedImages.value.clear();
    selectedSource.value = selectedSource.value;
    selectedImage.value = null;
    caption.value = ''; // Clear caption too
  }

  // Method to set the caption for the selected image
  void setCaption(String newCaption) {
    caption.value = newCaption;
  }
}
