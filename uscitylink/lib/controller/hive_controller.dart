import 'dart:io';

import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';

class HiveController extends GetxController {
  final _apiService = NetworkApiService();
  void uploadQueeueMedia() async {
    final mediaQueueBox = await Constant.getMediaQueueBox();

    for (int i = 0; i < mediaQueueBox.length; i++) {
      final media = mediaQueueBox.getAt(i);
      if (media == null) continue;

      final file = File(media["file"]);

      if (await file.exists()) {
        try {
          final url = "${Constant.url}/media/uploadFileQueue"
              "?groupId=${media["groupId"] ?? ''}"
              "&userId=${media["userId"] ?? ''}"
              "&source=${media["location"] ?? 'media'}"
              "&location=${media["type"] ?? ''}"
              "&uploadBy=${media["uploadBy"] ?? 'driver'}"
              "&tempId=${media["tempId"] ?? ''}";

          final res = await _apiService.multiFileUpload(
            [file],
            url,
            media["channelId"],
            media["body"],
          );

          if (res.status) {
            await mediaQueueBox.deleteAt(i);
            i--; // Adjust index
          } else {
            media["status"] = "failed";
            await mediaQueueBox.putAt(i, media);
          }
        } catch (e) {
          print("Upload error at index $i: $e");
          if (e.toString() == "No Internet Connection") {
            await Future.delayed(Duration(seconds: 10));
            i--;
          }
          // 🔁 Retry after delay if network error
          await mediaQueueBox.deleteAt(i);
          i--;
        }
      } else {
        // File missing, remove from box
        await mediaQueueBox.deleteAt(i);
        i--;
      }
    }
  }
}
