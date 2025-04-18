import 'dart:io';
import 'dart:math';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/widgets/photo_preview.dart';
import 'package:uscitylink/views/widgets/photo_preview_multiple.dart';
import 'package:uscitylink/views/widgets/video_preview_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImagePickerController extends GetxController {
  final _apiService = NetworkApiService();
  SocketService socketService = Get.find<SocketService>();
  MessageController _messageController = Get.find<MessageController>();
  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<List<File>> selectedImages = Rx<List<File>>([]);
  Rx<List<XFile>> selectedXImages = Rx<List<XFile>>([]);
  Rx<File?> selectedVideo = Rx<File?>(null);
  RxString caption = ''.obs;
  RxString selectedSource = ''.obs;
  NetworkService networkService = Get.find<NetworkService>();
  HiveController _hiveController = Get.find<HiveController>();
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
      String? groupId, String source, String userId, String uploadBy) async {
    try {
      selectedSource.value = "gallery";
      isLoading.value = true;
      // final XFile? image = await _picker.pickMultiImage(
      //     source: ImageSource.gallery, imageQuality: 25);
      final List<XFile>? images =
          await _picker.pickMultiImage(imageQuality: 25);

      if (images!.length > 0) {
        if (images != null && images.isNotEmpty) {
          for (var item in images) {
            selectedImages.value.add(File(item.path)); // XFile → File via .path
            selectedXImages.value.add(item); // XFile → File via .path
          }
        }
        isLoading.value = false;
        Get.to(() => PhotoPreviewMultiple(
            channelId: channelId,
            type: "media",
            location: location,
            groupId: groupId,
            source: source,
            userId: userId,
            uploadBy: uploadBy));
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

  // Method to upload a offline multiple file

  void uploadMultiFileOffline(String channelId, String type, String location,
      String? groupId, String? source, String? userId, String? uploadBy) async {
    final uuid = Uuid();

    final mediaQueueBox = await Constant.getMediaQueueBox();

    Map<String, dynamic> setRes = {
      "body": caption.value,
      "channelId": channelId,
      "groupId": groupId,
      "userId": userId,
      "source": location,
      "location": type,
      "uploadBy": uploadBy,
      "status": "pending",
      "media": []
    };

    for (XFile file in selectedXImages.value) {
      final savedFile = await saveToPermanentDirectory(file);

      String uuidPart = uuid.v4(); // Generate UUID (v4)
      String timestamp =
          DateTime.now().millisecondsSinceEpoch.toString(); // Current timestamp
      final random = Random();
      final randomNumber = random.nextInt(999999);
      // If the timestamp length exceeds, trim it down to fit within limits
      String trimmedTimestamp =
          timestamp.length > 6 ? timestamp.substring(0, 6) : timestamp;

      // Combine UUID and timestamp but ensure UUID is intact and within length limits
      String tempId = '$uuidPart-$trimmedTimestamp-$randomNumber';

      MessageModel messageOffline = MessageModel(
          id: tempId,
          body: caption.value,
          channelId: channelId,
          groupId: groupId,
          userProfileId: userId,
          url: savedFile.path,
          url_upload_type: "local-file",
          messageDirection: "R",
          status: "queue",
          deliveryStatus: "sent",
          messageTimestampUtc: DateTime.now().toUtc().toIso8601String());

      _messageController.insertNewMessageCache(messageOffline);
      _messageController.messages.refresh();
      // mediaQueueBox.add({
      //   "tempId": tempId,
      //   "body": caption.value,
      //   "channelId": channelId,
      //   "groupId": groupId,
      //   "userId": userId,
      //   "file": savedFile.path,
      //   "source": location,
      //   "location": type,
      //   "uploadBy": uploadBy,
      //   "status": "processing",
      // });
      (setRes["media"] as List).add({
        "tempId": tempId,
        "file": savedFile.path,
      });
    }
    int newKey = 0;
    while (mediaQueueBox.containsKey(newKey)) {
      newKey++;
    }

// Step 4: Save the full set to Hive
    await mediaQueueBox.put(newKey, setRes);

    selectedXImages.value.clear();
    selectedImages.value.clear();
    ;
    caption.value = '';
    if (networkService.isConnected) {
      _hiveController.uploadQueeueMedia();
      print("internet,${networkService.isConnected}");
    }
    Get.back();
    while (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  void uploadQueeueMedia() async {
    final mediaQueueBox = await Constant.getMediaQueueBox();
    int i = 0;
    for (var media in mediaQueueBox.values) {
      final file = File(media["file"]);

      if (await file.exists()) {
        try {
          var res = await _apiService.multiFileUpload([
            file
          ], "${Constant.url}/media/uploadFileQueue?groupId=${media["groupId"]}&userId=${media["userId"]}&source=${media["location"]}&location=${media["type"]}&uploadBy=${media["uploadBy"]}&tempId=${media["tempId"]}",
              media["channelId"], media["body"]);

          if (res.status) {
            await mediaQueueBox.deleteAt(i);
            i = i + 1;
          }
        } catch (e) {
          print(e.toString());
          // Utils.snackBar("File Upload Error", e.toString());
          //await mediaQueueBox.deleteAt(i);
        }
      } else {
        await mediaQueueBox.deleteAt(i);
      }
    }
    mediaQueueBox.close();
  }

  // Method to upload multiple files

  void uploadMultiFile(String channelId, String type, String location,
      String? groupId, String? source, String? userId, String? uploadBy) async {
    try {
      var res = await _apiService.multiFileUpload(
          selectedImages.value!,
          "${Constant.url}/media/uploadFileQueue?groupId=$groupId&userId=$userId&source=$location&location=$type&uploadBy=$uploadBy",
          channelId,
          caption.value);

      if (res.status) {
        selectedImages.value.clear();
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
            socketService.sendMessage(caption.value, res.data.key!, channelId,
                res.data.thumbnail, "", "server");
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

  Future<File> saveToPermanentDirectory(XFile xfile) async {
    final appDir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileExtension = p.extension(xfile.path);
    final uniqueName = 'media_$timestamp$fileExtension';
    final savedImage =
        await File(xfile.path).copy('${appDir.path}/$uniqueName');
    return savedImage;
  }
}
