import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/dashboard_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';

class Constant {
  static const String baseUrl = 'http://52.9.12.189:4300/api';
  static const String tempImageUrl = 'http://52.9.12.189:4300/';

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
      // Access the box with the correct type
      return Hive.box<dynamic>(boxName);
    } else {
      // Open the box with the specified type
      return await Hive.openBox<dynamic>(boxName);
    }
  }

// 1. First, define a box that stores dynamic lists
  static Future<Box> getChannelMessagesBox() async {
    const boxName = 'channelMessages';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    } else {
      // Register adapter if needed
      // if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId)) {
      //   Hive.registerAdapter(MessageModelAdapter());
      // }
      return await Hive.openBox(boxName);
    }
  }

  static Future<Box<UserChannelModel>> getUserChannelBox() async {
    const boxName = HiveBoxes.userChannel;

    if (Hive.isBoxOpen(boxName)) {
      // Access the box with the correct type
      return Hive.box<UserChannelModel>(boxName);
    } else {
      // Open the box with the specified type
      return await Hive.openBox<UserChannelModel>(boxName);
    }
  }

  static Future<Box<DashboardModel>> getDriverDashboardBox() async {
    const boxName = HiveBoxes.driverDashboard;

    if (Hive.isBoxOpen(boxName)) {
      // Access the box with the correct type
      return Hive.box<DashboardModel>(boxName);
    } else {
      // Open the box with the specified type
      return await Hive.openBox<DashboardModel>(boxName);
    }
  }
}
