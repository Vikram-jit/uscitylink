// ignore_for_file: unnecessary_set_literal

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/channel_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
import 'package:uscitylink/services/staff_services/chat_service.dart';
import 'package:uscitylink/utils/utils.dart';

class StaffchannelController extends GetxController {
  var channels = <ChannelModel>[].obs;
  var channelMebers = <ChannelMemberModel>[].obs;
  var drivers = <DriverModel>[].obs;
  var driverFilter = <DriverModel>[].obs;
  var loading = false.obs;
  var selectedDriversIds = <String>[].obs;
  var channelChatUser = ChannelChatUserModel().obs;
  final __channelService = ChannelService();
  StaffgroupController _staffgroupController = Get.put(StaffgroupController());
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  final _chatService = ChatService();
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  SocketService _socketService = Get.find<SocketService>();

  void onSearchChanged(String query) {
    // If the previous timer is active, cancel it
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    // Start a new timer for debounce (500ms delay)
    _debounce = Timer(const Duration(milliseconds: 200), () {
      getChnnelChatUser(1, query);
    });
  }

  void getUserChannels() {
    loading.value = true;
    __channelService.getChannelList().then((response) {
      channels.value = response.data;
      loading.value = false;
    }).onError((error, stackTrace) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    });
  }

  void searchDrivers(String query) {
    if (query.isEmpty) {
      // If the query is empty, reset the list to all drivers
      drivers.value = driverFilter;
    } else {
      var filteredDrivers = driverFilter.where((driver) {
        // Safely check if profiles exists and if username contains the query
        return driver.profiles != null &&
            driver.profiles!.isNotEmpty &&
            driver.profiles![0].username != null &&
            driver.profiles![0].username!
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();

      // Update the observable list with the filtered results
      drivers.value = filteredDrivers;
    }
  }

  Future<void> getChannelMembers() async {
    loading.value = true;

    try {
      var response = await __channelService.getStaffChannelMember();
      channelMebers.value = response.data;
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> deleteMember(String id) async {
    if (channelMebers.isNotEmpty) {
      channelMebers.removeWhere((item) => item.userProfileId == id);
      channelMebers?.refresh();
    }

    if (channelChatUser.value.userChannels!.isNotEmpty) {
      var index = channelChatUser.value.userChannels
          ?.indexWhere((item) => item.userProfileId == id);

      channelChatUser.value.userChannels
          ?.removeWhere((item) => item.userProfileId == id);
      channelChatUser.refresh();
      refresh();
    }

    loading.value = true;

    try {
      // Fetch messages from the server with pagination.
      var response = await _chatService.deletedById(id);

      // Check if the response is valid
      if (response.status) {
        Utils.toastMessage(response.message);
      }
    } catch (error) {
      // Handle error by showing a snack bar
      Utils.snackBar('Error', error.toString());
    } finally {
      // Ensure loading state is reset
      loading.value = false;
    }
  }

  Future<void> getChnnelChatUser(int page, String search) async {
    if (loading.value) return;
    loading.value = true;

    try {
      var response = await __channelService.getChatUserChannel(
          page, searchController.text);

      if (response.data != null) {
        if (page > 1) {
          channelChatUser.value?.userChannels
              ?.addAll(response.data.userChannels ?? []);
        } else {
          channelChatUser.value = response.data;
        }

        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        Utils.snackBar('No data', 'No user found.');
      }
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> getDrivers() async {
    loading.value = true;
    try {
      selectedDriversIds.value = [];
      var response = await __channelService.getStaffDrivers();
      response.data.forEach((driver) => {
            if (driver.profiles?.isNotEmpty == true)
              {
                if (driver.isChannelExist == true)
                  {selectedDriversIds.add(driver.profiles![0].id!)}
              }
          });
      drivers.value = response.data;
      driverFilter.value = response.data;
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> getGroupDrivers(String groupId) async {
    loading.value = true;
    try {
      selectedDriversIds.value = [];
      var response = await __channelService.getStaffGroupDrivers(groupId);
      response.data.forEach((driver) => {
            if (driver.profiles?.isNotEmpty == true)
              {
                if (driver.isChannelExist == true)
                  {selectedDriversIds.add(driver.profiles![0].id!)}
              }
          });
      drivers.value = response.data;
      driverFilter.value = response.data;
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  void addMemberIntoChannel(String id, bool value) async {
    loading.value = true;
    var index = drivers.indexWhere((member) => member.id == id);
    if (index.isNegative == false) {
      drivers[index].isChannelExist = value;

      if (value) {
        selectedDriversIds.refresh();
      } else {
        selectedDriversIds.remove(drivers[index]!.profiles![0].id!);
        selectedDriversIds.refresh();
      }

      drivers.refresh();

      var response = await __channelService
          .updateChannelMembers(drivers[index]!.profiles![0].id!);

      if (response.status) {
        await getChannelMembers();
        await getChnnelChatUser(currentPage.value, searchController.text);
      }

      loading.value = false;
    }
    loading.value = false;
  }

  void addMemberIntoGroup(String id, bool value, String groupId) async {
    try {
      if (Get.isRegistered<GroupController>()) {
        GroupController _staffgroupController = Get.find<GroupController>();

        loading.value = true;

        var index = drivers.indexWhere((member) => member.id == id);
        var response = await __channelService.updateGroupMembers(
            drivers[index]!.profiles![0].id!, groupId);

        if (response.status) {
          _staffgroupController.updateGroupMember(response.data);
        }
        if (index.isNegative == false) {
          drivers[index].isChannelExist = value;

          if (value) {
            selectedDriversIds.refresh();
          } else {
            selectedDriversIds.remove(drivers[index]!.profiles![0].id!);
            selectedDriversIds.refresh();
          }

          drivers.refresh();

          loading.value = false;
        }
        loading.value = false;
      }
    } catch (e) {
      loading.value = false;
      Utils.toastMessage(e.toString());
    }
  }

  Future<void> updateActiveChannel(String id) async {
    loading.value = true;

    try {
      var response = await __channelService.updateActiveChannel(id);
      channelMebers.clear();
      selectedDriversIds.clear();

      getUserChannels();
      currentPage.value = 1;
      searchController.text = "";
      getChnnelChatUser(currentPage.value, searchController.text);

      _staffgroupController.getGroups(1, "");

      channelChatUser.refresh();
      channels.refresh();
      _staffgroupController.update();
      _staffgroupController.groups.refresh();
      if (_socketService.isConnected.value) {
        _socketService.switchStaffChannel(id);
      }
    } catch (error) {
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }

  void updateOnlineStatusMember(
      String userId, String channelId, bool isOnline) {
    if (channelChatUser.value.id != null) {
      if (channelChatUser.value.userChannels?.isNotEmpty ?? false) {
        var member = channelChatUser.value.userChannels?.firstWhere(
          (member) {
            return member.userProfileId == userId;
          },
          orElse: () => UserChannels(),
        );
        if (member?.id != null) {
          member?.userProfile?.isOnline = isOnline ?? false;
          channelChatUser.refresh();
        }
      }
    }
  }

// Update a channel with a new message
  void updateCount(String channelId, String userId) {
    try {
      if (channelChatUser.value.id != null) {
        if (channelChatUser.value.userChannels?.isNotEmpty ?? false) {
          var member = channelChatUser.value.userChannels?.firstWhere(
            (member) {
              return member.userProfileId == userId &&
                  member.channelId == channelId;
            },
            orElse: () => UserChannels(),
          );
          if (member?.id != null) {
            member?.unreadCount = 0;
            channelChatUser.refresh();
          }
        }
      }
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  // Update a channel with a new message
  void addNewMessageWithouIncrement(dynamic messageData) {
    try {
      LastMessage message = LastMessage.fromJson(messageData['message']);

      String userId = message.userProfileId!;
      String channelId = message.channelId!;

      if (channelChatUser.value.id != null) {
        if (channelChatUser.value.userChannels?.isNotEmpty ?? false) {
          var member = channelChatUser.value.userChannels?.firstWhere(
            (member) {
              return member.userProfileId == userId &&
                  member.channelId == channelId;
            },
            orElse: () => UserChannels(),
          );
          if (member?.id != null) {
            member?.lastMessage = message;
            member?.sentMessageCount = (member.sentMessageCount ?? 0) + 1;
            channelChatUser.refresh();
          }
        }
      }
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  void addNewMessage(dynamic messageData) {
    try {
      LastMessage message = LastMessage.fromJson(messageData);

      String userId = message.userProfileId!;
      String channelId = message.channelId!;

      if (channelChatUser.value.id != null) {
        if (channelChatUser.value.userChannels?.isNotEmpty ?? false) {
          var member = channelChatUser.value.userChannels?.firstWhere(
            (member) {
              return member.userProfileId == userId &&
                  member.channelId == channelId;
            },
            orElse: () => UserChannels(),
          );
          if (member?.id != null) {
            member?.lastMessage = message;
            channelChatUser.refresh();
          }
        }
      }
    } catch (e) {
      print("Error while adding new message: $e");
    }
  }

  @override
  void onClose() {
    // Cancel debounce timer when the controller is disposed
    _debounce?.cancel();
    super.onClose();
  }
}
