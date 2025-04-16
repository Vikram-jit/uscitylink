import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class HiveController extends GetxController {
  final _apiService = NetworkApiService();
  void uploadQueeueMedia() async {
    final mediaQueueBox = await Constant.getMediaQueueBox();

    for (int i = 0; i < mediaQueueBox.length; i++) {
      final media = mediaQueueBox.getAt(i);
      if (media == null) continue;

      final file = File(media["file"]);
      if (await file.exists()) {
        File? fileToUpload = file;
        XFile? compressedFile;

        try {
          final ext = p.extension(file.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png'].contains(ext)) {
            final tempDir = await getTemporaryDirectory();
            final targetPath =
                "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext";

            compressedFile = await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: 50,
            );

            if (compressedFile != null) {
              fileToUpload = File(compressedFile.path);
            }
          }

          final url = "${Constant.url}/media/uploadFileQueue"
              "?groupId=${media["groupId"] ?? ''}"
              "&userId=${media["userId"] ?? ''}"
              "&source=${media["location"] ?? 'media'}"
              "&location=${media["type"] ?? ''}"
              "&uploadBy=${media["uploadBy"] ?? 'driver'}"
              "&tempId=${media["tempId"] ?? ''}";

          final res = await _apiService.multiFileUpload(
            [fileToUpload!],
            url,
            media["channelId"],
            media["body"],
          );

          if (res.status) {
            await mediaQueueBox.deleteAt(i);
            i--;
          } else {
            media["status"] = "failed";
            await mediaQueueBox.putAt(i, media);
          }
        } catch (e) {
          print("Upload error at index $i: $e");

          if (e.toString().contains("No Internet Connection")) {
            await Future.delayed(Duration(seconds: 10));
            i--;
          } else {
            await mediaQueueBox.deleteAt(i);
            i--;
          }
        } finally {
          // Clean up compressed file if it exists
          if (compressedFile != null &&
              await File(compressedFile.path).exists()) {
            await File(compressedFile.path).delete();
            print("Compressed file deleted.");
          }
        }
      } else {
        await mediaQueueBox.deleteAt(i);
        i--;
      }
    }
  }
}
