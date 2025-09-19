import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/user_channel_model.dart';
import 'package:uscitylink/services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';
// import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';

class ChannelController extends GetxController {
  var channels = <UserChannelModel>[].obs;
  var innerTabIndex = 0.obs;
  var doucumentInnerTabIndex = 0.obs;
  var loading = false.obs;
  final __channelService = ChannelService();
  final _truckController = TruckController();
  final _trainingController = TrainingController();
  var currentIndex = 0.obs;
  var totalUnReadMessage = 0.obs;
  var channelCount = 0.obs;
  var groupCount = 0.obs;

  RxBool isSupportBadge = false.obs;

  GroupController groupController = Get.put(GroupController());
  DashboardController dashboardController = Get.put(DashboardController());
  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      if (index == 0) {
        dashboardController.getDashboard();
        getCount();
      }
      if (index == 1) {
        getUserChannels();
        getCount();
      }
      if (index == 2) {
        _truckController.fetchTrucks();
        getCount();
      }
      if (index == 3) {
        _trainingController.fetchTrainingVideos(page: 1);
        getCount();
      }
    });
    innerTabIndex.listen((index) {
      if (index == 0) {
        getUserChannels();
        getCount();
      }
      if (index == 1) {
        groupController.getUserGroups();
        getCount();
      }
    });
  }

  void getUserChannels() async {
    Box userChannelBox = await Constant.getUserChannelBox();
    loading.value = true;
    totalUnReadMessage.value = 0;

    // 1️⃣ Try loading from cache first
    if (userChannelBox.isNotEmpty) {
      // Get all values from the box
      final cachedList = userChannelBox.values.toList();

      // Ensure type safety
      List<UserChannelModel> cachedChannels =
          cachedList.cast<UserChannelModel>();

      channels.value = cachedChannels;
      loading.value = false;
      return; // Already showing cached data, stop further execution
    }

    // 2️⃣ Only load from API if cache is empty
    try {
      final response = await __channelService.getUserChannels();

      // Save list to Hive
      await userChannelBox.clear(); // Optional: clear old entries
      for (var channel in response.data) {
        await userChannelBox.put(channel.id, channel);
      }

      // Update observable with data from API
      channels.value = response.data;
      loading.value = false;
    } catch (error) {
      // Stop loading if error occurs
      loading.value = false;

      if (channels.isEmpty &&
          error.toString() == "Exception: No Internet Connection") {
        Utils.snackBar('Offline', 'No Internet Connection');
      } else {
        Utils.snackBar('Error', error.toString());
      }
    }
  }

  void getCount() {
    loading.value = true;
    totalUnReadMessage.value = 0;

    __channelService.getCount().then((response) async {
      FlutterAppBadgeControl.isAppBadgeSupported().then((res) async {
        await FlutterAppBadgeControl.updateBadgeCount(response.data.total ?? 0);
      });

      totalUnReadMessage.value = response.data.total ?? 0;
      channelCount.value = response.data.channel ?? 0;
      groupCount.value = response.data.group ?? 0;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      //Utils.snackBar('Error', error.toString());
    });
  }

  // Set the current index
  void setTabIndex(int index) {
    currentIndex.value = index;
  }

  void setDopcuemntTabIndex(int index) {
    doucumentInnerTabIndex.value = index;
  }

  void setInnerTabIndex(int index) {
    innerTabIndex.value = index;
  }

  // Update a channel with a new message
  void addNewMessage(dynamic messageData) {
    try {
      MessageModel message = MessageModel.fromJson(messageData);

      String channelId = message.channelId!;

      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.updateWithNewMessage(message);

      channels.removeWhere((ch) => ch.channelId == channelId);
      channels.insert(0, channel);

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void addNewChannel(dynamic data) {
    UserChannelModel userChannelModel = UserChannelModel.fromJson(data);

    channels.insert(0, userChannelModel);

    channels.refresh();
  }

  void updateCount(String channelId) {
    try {
      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.recieve_message_count = 0;

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void incrementCount(String channelId) {
    try {
      var channel = channels.firstWhere(
        (ch) => ch.channelId == channelId,
        orElse: () => UserChannelModel(id: channelId),
      );

      channel.recieve_message_count = (channel.recieve_message_count ?? 0) + 1;

      channels.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }
}
