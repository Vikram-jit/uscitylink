import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/message_model.dart';

class Constant {
  static const String baseUrl = 'http://localhost:4300/api';

  static const String versionApi = "v1";

  static const url = '$baseUrl/$versionApi';

  static const aws = "https://ciity-sms.s3.us-west-1.amazonaws.com";

  static Future<Box<MessageModel>> getQueueMessageBox() async {
    const boxName = HiveBoxes.queueMessageBox;

    if (Hive.isBoxOpen(boxName)) {
      // Access the box with the correct type
      return Hive.box<MessageModel>(boxName);
    } else {
      // Open the box with the specified type
      return await Hive.openBox<MessageModel>(boxName);
    }
  }

  static Future<Box<dynamic>> getMediaQueueBox() async {
    const boxName = HiveBoxes.mediaQueueBox;

    if (Hive.isBoxOpen(boxName)) {
      var box = Hive.box(boxName);

      // Ensure the type is correct
      if (box is Box<dynamic>) {
        return box;
      } else {
        // Mismatch found, close and reopen with correct type
        await box.close();
        return await Hive.openBox<dynamic>(boxName);
      }
    }

    return await Hive.openBox<dynamic>(boxName);
  }
}
