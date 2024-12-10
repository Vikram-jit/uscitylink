import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/widgets/photo_preview.dart';

class ImagePickerController extends GetxController {
  final _apiService = NetworkApiService();
  SocketService socketService = Get.find<SocketService>();

  Rx<File?> selectedImage = Rx<File?>(null);
  RxString caption = ''.obs;
  RxString selectedSource = ''.obs;

  final ImagePicker _picker = ImagePicker();
  var isLoading = false.obs; // Loading state for image
  Future<void> pickImageFromCamera(
      String channelId, String location, String? groupId) async {
    try {
      isLoading.value = true;
      selectedSource.value = "camera";
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        selectedImage.value = File(image.path);
        isLoading.value = false;
        Get.to(() => PhotoPreviewScreen(
              channelId: channelId,
              type: "media",
              location: location,
              groupId: groupId,
            ));
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }

  Future<void> pickImageFromGallery(
      String channelId, String location, String? groupId) async {
    try {
      selectedSource.value = "gallery";
      isLoading.value = true;
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        selectedImage.value = File(image.path);
        isLoading.value = false;
        Get.to(() => PhotoPreviewScreen(
              channelId: channelId,
              type: "media",
              location: location,
              groupId: groupId,
            ));
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
  }

  void uploadFile(
      String channelId, String type, String location, String? groupId) async {
    try {
      var res = await _apiService.fileUpload(selectedImage.value!,
          "${Constant.url}/message/fileUpload", channelId, type);
      if (res.status) {
        if (location == "group") {
          socketService.sendGroupMessage(
              groupId!, channelId, caption.value, res.data.key!);
        } else {
          socketService.sendMessage(caption.value, res.data.key!);
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

  void clearSelectedImage() {
    selectedSource.value = selectedSource.value;
    selectedImage.value = null;
    caption.value = ''; // Clear caption too
  }

  // Method to set the caption for the selected image
  void setCaption(String newCaption) {
    caption.value = newCaption;
  }
}
