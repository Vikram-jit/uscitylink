import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/truck_group_model.dart';

import 'package:uscitylink/services/group_service.dart';
import 'package:uscitylink/services/message_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';

class GroupController extends GetxController {
  SocketService socketService = Get.find<SocketService>();

  var groups = <GroupModel>[].obs;
  var loading = false.obs;
  var isLoading = false.obs;
  var messages = <MessageModel>[].obs;
  var truckMessages = <Messages>[].obs;
  final __groupService = GroupService();
  final __messageService = MessageService();
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var previousGroupId = ''.obs;
  final group = GroupSingleModel().obs;
  var templateurl = "".obs;

  Timer? typingTimer;
  late DateTime typingStartTime;
  var isTyping = false.obs;
  var typing = false.obs;
  var typingMessage = "".obs;
  var openGroupId = "".obs;
  var currentIndex = 0.obs;
  var senderId = "".obs;

  var truckGroup = TruckGroupModel().obs;

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
    openGroupId.value = groupId;
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

// Start typing event
  void startTyping(String groupId) {
    if (typingTimer != null && typingTimer!.isActive) {
      typingTimer!.cancel();
    }

    isTyping.value = true;
    socketService.socket
        .emit('groupTyping', {'isTyping': true, "groupId": groupId});

    typingStartTime = DateTime.now();

    // Stop typing after 1.5 seconds of inactivity
    typingTimer = Timer(const Duration(seconds: 1), () {
      if (DateTime.now().difference(typingStartTime).inSeconds >= 1) {
        stopTyping(groupId);
      }
    });
  }

  // Stop typing event
  void stopTyping(String groupId) {
    isTyping.value = false;
    socketService.socket
        .emit('groupTyping', {'isTyping': false, "groupId": groupId});
  }

  void getGroupMessages(String channelId, String groupId, int page) {
    // Debugging logs to track the page number and loading state
    openGroupId.value = groupId;
    if (isLoading.value) return;

    // Set the loading state to true
    isLoading.value = true;

    // Simulating API call (replace with your actual API call)
    __messageService
        .getGroupMessages(channelId, groupId, page)
        .then((response) {
      // Check the response structure
      if (page > 1) {
        if (response.data.messages != null) {
          messages.addAll(response.data.messages ?? []);
        }
      } else {
        if (response.data.messages != null) {
          messages.value = response.data.messages ?? [];
        }
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

  void getTruckGroupMessages(String groupId, int page) {
    // Debugging logs to track the page number and loading state
    openGroupId.value = groupId;
    if (isLoading.value) return;

    isLoading.value = true;

    __messageService.getTruckGroupMessages(groupId, page).then((response) {
      if (response.status) {
        truckGroup.value = response.data;
        truckMessages.addAll(response.data.messages ?? []);
      }

      if (response.data.pagination != null) {
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

  void updateTypingStatus(dynamic data) {
    if (data['groupId'] == openGroupId.value) {
      typing.value = data['typing'];
      typingMessage.value = data['message'];
    }
  }

  void onNewMessageToTruck(dynamic data) {
    Messages newMessage = Messages.fromJson(data);
    if (truckGroup.value.group?.id == newMessage.groupId) {
      truckMessages.insert(0, newMessage);
      truckMessages.refresh();
    }
  }

  void updateGroupMember(EventGroupMemberModel _model) {
    print(jsonEncode(_model));
    if (_model.event == "add") {
      if (_model.member != null) {
        group.value.groupMembers?.add(_model.member!);
      }
    } else {
      if (_model.member != null) {
        group.value.groupMembers?.removeWhere((item) {
          return item.id == _model.member!.id;
        });
      }
    }
    group.refresh();
    // Instead of _staffgroupController.group.refresh(), use:
  }
}
