import 'dart:io';

import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';

class HiveController extends GetxController {
  final _apiService = NetworkApiService();
  void uploadQueeueMedia() async {
    final mediaQueueBox = await Constant.getMediaQueueBox();
    final List<int> successIndexes = [];

    for (int i = 0; i < mediaQueueBox.length; i++) {
      final media = mediaQueueBox.getAt(i);
      if (media == null) continue;

      final file = File(media["file"]);

      if (await file.exists()) {
        try {
          final res = await _apiService.multiFileUpload(
            [file],
            "${Constant.url}/media/uploadFileQueue"
            "?groupId=${media["groupId"]}"
            "&userId=${media["userId"]}"
            "&source=${media["location"]}"
            "&location=${media["type"]}"
            "&uploadBy=${media["uploadBy"]}"
            "&tempId=${media["tempId"]}",
            media["channelId"],
            media["body"],
          );

          if (res.status) {
            successIndexes.add(i); // Mark for deletion later
          } else {
            media["status"] = "failed";
            await mediaQueueBox.putAt(i, media);
          }
        } catch (e) {
          print("Upload error at index $i: $e");
        }
      } else {
        // File no longer exists — mark for deletion
        successIndexes.add(i);
      }
    }

    // 🔄 Delete successful uploads (in reverse to avoid index shift)
    for (int index in successIndexes.reversed) {
      await mediaQueueBox.deleteAt(index);
    }
  }
}
