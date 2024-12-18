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
  var isLoading = false.obs;
  var messages = <MessageModel>[].obs;
  final __groupService = GroupService();
  final __messageService = MessageService();
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var previousGroupId = ''.obs;
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
      getGroupMessages(channelId, groupId, currentPage.value);
    } else {
      print("Error: channelId and groupId is empty or invalid.");
    }
  }

  Future<void> refreshMessages(String channelId, String groupId) async {
    // Prevent refresh if already loading
    if (isLoading.value) return;

    // Set loading state to true
    isLoading.value = true;

    try {
      // Replace with your actual API call to fetch messages
      var response = await __messageService.getGroupMessages(
        channelId,
        groupId,
        1,
      );

      // Check if there are new messages
      if (response.data.messages != null &&
          response.data.messages!.isNotEmpty) {
        List<MessageModel> newMessages = response.data.messages!;

        List<MessageModel> newMessageList = [];

        for (var newMessage in newMessages) {
          bool isNewMessage = true;

          for (var existingMessage in messages) {
            if (newMessage.id == existingMessage.id) {
              isNewMessage = false;
              break;
            }
          }

          if (isNewMessage) {
            newMessageList.add(newMessage);
          }
        }

        if (newMessageList.isNotEmpty) {
          messages.insertAll(0, newMessageList);
        }
      }
    } catch (error) {
      print('Error refreshing messages: $error');
      Utils.snackBar('Error', 'Failed to refresh messages');
    } finally {
      // Reset loading state
      isLoading.value = false;
    }
  }

  void getGroupMessages(String channelId, String groupId, int page) {
    // Debugging logs to track the page number and loading state

    // Prevent duplicate requests if already loading
    if (isLoading.value) return;

    // Set the loading state to true
    isLoading.value = true;
    // if (previousGroupId.value != groupId) {
    //   // Clear messages if the groupId has changed
    //   messages.clear();
    //   previousGroupId.value = groupId; // Update the stored groupId
    // }
    // Simulating API call (replace with your actual API call)
    __messageService
        .getGroupMessages(channelId, groupId, page)
        .then((response) {
      // Check the response structure

      // Safeguard to ensure response contains messages and pagination info
      if (response.data.messages != null) {
        messages.addAll(response.data.messages ?? []);
      }

      if (response.data.pagination != null) {
        senderId.value = response.data.senderId ?? '';
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        print("Pagination data is missing in the response!");
      }

      // Reset loading state after processing response
      isLoading.value = false;
    }).onError((error, stackTrace) {
      // Handle error
      print("Error: $error");
      Utils.snackBar('Error', error.toString());

      // Reset loading state in case of error as well
      isLoading.value = false;
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
