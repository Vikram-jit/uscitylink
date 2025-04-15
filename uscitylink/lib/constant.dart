import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/message_model.dart';

class Constant {
  static const String baseUrl = 'http://52.9.12.189:3004/api';

  static const String versionApi = "v1";

  static const url = '$baseUrl/$versionApi';

  static const aws = "https://ciity-sms.s3.us-west-1.amazonaws.com";

  static Future<Box<MessageModel>> getQueueMessageBox() async {
    const boxName = HiveBoxes.queueMessageBox;

    if (Hive.isBoxOpen(boxName)) {
      var box = Hive.box(boxName);

      // Ensure the type is correct
      if (box is Box<MessageModel>) {
        return box;
      } else {
        // 💥 Mismatch found, close and reopen with correct type
        await box.close();
        return await Hive.openBox<MessageModel>(boxName);
      }
    }

    return await Hive.openBox<MessageModel>(boxName);
  }

  static Future<Box<dynamic>> getMediaQueueBox() async {
    const boxName = HiveBoxes.mediaQueueBox;

    if (Hive.isBoxOpen(boxName)) {
      var box = Hive.box(boxName);

      // Ensure the type is correct
      if (box is Box<dynamic>) {
        return box;
      } else {
        // 💥 Mismatch found, close and reopen with correct type
        await box.close();
        return await Hive.openBox<dynamic>(boxName);
      }
    }

    return await Hive.openBox<dynamic>(boxName);
  }
}
