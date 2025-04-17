import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/message_model.dart';

class HiveController extends GetxController {
  final _apiService = NetworkApiService();
  RxBool isProcessing = false.obs;

  Future<void> uploadQueeueMedia() async {
    if (isProcessing.value) {
      print("Already processing. Skipping new call.");
      return;
    }

    isProcessing.value = true;
    print("Starting media upload queue...");

    try {
      final mediaQueueBox = await Constant.getMediaQueueBox();

      while (true) {
        bool foundPending = false;

        await Future.forEach<int>(
            List<int>.generate(mediaQueueBox.length, (i) => i), (int i) async {
          final mediaBatch = mediaQueueBox.getAt(i);

          if (mediaBatch == null) return;

          List mediaList = mediaBatch["media"] ?? [];
          String status = mediaBatch["status"] ?? "pending";

          if (status != "pending" || mediaList.isEmpty) return;

          foundPending = true;
          mediaBatch["status"] = "processing";
          await mediaQueueBox.putAt(i, mediaBatch);

          List newMediaList = [];

          await Future.forEach(mediaList, (dynamic media) async {
            final file = File(media["file"]);

            if (await file.exists()) {
              File? fileToUpload = file;
              XFile? compressedFile;

              try {
                final ext = p.extension(file.path).toLowerCase();
                if (['.jpg', '.jpeg', '.png'].contains(ext)) {
                  final tempDir = await getTemporaryDirectory();
                  final targetPath =
                      "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

                  compressedFile =
                      await FlutterImageCompress.compressAndGetFile(
                    file.absolute.path,
                    targetPath,
                    quality: 50,
                  );

                  if (compressedFile != null) {
                    fileToUpload = File(compressedFile.path);
                  }
                }

                final url = "${Constant.url}/media/uploadFileQueue"
                    "?groupId=${mediaBatch["groupId"] ?? ''}"
                    "&userId=${mediaBatch["userId"] ?? ''}"
                    "&source=${mediaBatch["source"] ?? 'media'}"
                    "&location=${mediaBatch["location"] ?? ''}"
                    "&uploadBy=${mediaBatch["uploadBy"] ?? 'driver'}"
                    "&tempId=${media["tempId"] ?? ''}";

                final res = await _apiService.multiFileUpload(
                  [fileToUpload!],
                  url,
                  mediaBatch["channelId"],
                  mediaBatch["body"],
                );

                if (res.status) {
                  if (compressedFile != null &&
                      await File(compressedFile.path).exists()) {
                    await File(compressedFile.path).delete();
                  }
                  await file.delete();
                } else {
                  newMediaList.add(media);
                }
              } catch (e) {
                print("Upload error: $e");
                if (!e.toString().contains("No Internet Connection")) {
                  newMediaList.add(media);
                }
              }
            } else {
              newMediaList.add(media);
            }
          });

          // Update batch status after processing all media in it
          if (newMediaList.isEmpty) {
            mediaBatch["media"] = [];
            mediaBatch["status"] = "completed";
            await mediaQueueBox.putAt(i, mediaBatch);
          } else {
            mediaBatch["media"] = newMediaList;
            mediaBatch["status"] = "pending";
            await mediaQueueBox.putAt(i, mediaBatch);
          }
        });

        if (!foundPending) {
          break; // No more pending media batches to process
        }
      }
    } catch (e) {
      print("Unexpected error in uploadQueeueMedia: $e");
    } finally {
      isProcessing.value = false;
      print("Upload media queue finished.");
    }
  }

  void updateSeenStatus(String channelId, String tempId) async {
    final box = await Hive.openBox(HiveBoxes.channelMessages);

    for (var key in box.keys) {
      if (key.toString().startsWith(channelId)) {
        final messages = (box.get(key) as List?)?.cast<MessageModel>() ?? [];

        for (int i = 0; i < messages.length; i++) {
          if (messages[i].id == tempId) {
            messages[i].url_upload_type = "failed"; // Update directly
            await box.put(key, messages); // Save updated lis
            return;
          }
        }
      }
    }
  }
}
