import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/message_model.dart';

import 'package:uscitylink/services/group_service.dart';
import 'package:uscitylink/services/message_service.dart';
import 'package:uscitylink/utils/utils.dart';

class GroupController extends GetxController {
  var groups = <GroupModel>[].obs;
  var loading = false.obs;
  var messages = <MessageModel>[].obs;
  final __groupService = GroupService();
  final __messageService = MessageService();

  final group = GroupSingleModel().obs;

  var currentIndex = 0.obs;
  var senderId = "".obs;
  @override
  void onInit() {
    super.onInit();
    currentIndex.listen((index) {
      // Call getUserChannels whenever the tab index changes
      if (index == 1) {
        getUserGroups(); // Fetch channels when tab 0 is selected
      }
    });

    Map args = Get.arguments as Map? ?? {};

    String channelId = args['channelId'] ?? '';
    String groupId = args['groupId'] ?? '';

    if (channelId.isNotEmpty && groupId.isNotEmpty) {
      getGroupMessages(channelId, groupId);
    } else {
      print("Error: channelId and groupId is empty or invalid.");
    }
  }

  void getGroupMessages(String channelId, String groupId) {
    __messageService.getGroupMessages(channelId, groupId).then((response) {
      messages.value = response.data.messages ?? [];
      senderId.value = response.data.senderId ?? '';
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  void getUserGroups() {
    loading.value = true;
    __groupService.getUserGroups().then((response) {
      groups.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void getGroupById(String groupId) {
    loading.value = true;
    __groupService.getGroupById(groupId).then((response) {
      if (response.status) {
        group.value = response.data;
      }

      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  // Set the current index
  void setTabIndex(int index) {
    currentIndex.value = index;
  }

  // Update a channel with a new message
  void addNewMessage(dynamic messageData) {
    try {
      MessageModel message = MessageModel.fromJson(messageData);

      String groupId = message.groupId!;

      var group = groups.firstWhere(
        (ch) => ch.groupId == groupId,
        orElse: () => GroupModel(groupId: groupId),
      );

      group.updateWithNewMessage(message);

      groups.removeWhere((ch) => ch.groupId == groupId);
      groups.insert(0, group);

      groups.refresh();
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void addNewGroup(dynamic data) {
    GroupModel groupUser = GroupModel.fromJson(data);

    groups.insert(0, groupUser);

    groups.refresh();
  }

  void onNewMessage(dynamic data) {
    // Assuming the incoming message is a Map or JSON object that can be parsed to MessageModel
    MessageModel newMessage = MessageModel.fromJson(data);

    messages.insert(0, newMessage);
    messages.refresh();
  }
}
