import 'dart:io';

import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/data/network/network_api_service.dart';

class HiveController extends GetxController {
  final _apiService = NetworkApiService();
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
    // mediaQueueBox.close();
  }
}
