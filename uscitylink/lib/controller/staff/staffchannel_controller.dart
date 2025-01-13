// ignore_for_file: unnecessary_set_literal

import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/model/group_members_model.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/channel_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
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

  SocketService _socketService = Get.find<SocketService>();
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

  Future<void> getChnnelChatUser() async {
    loading.value = true;

    try {
      var response = await __channelService.getChatUserChannel();

      channelChatUser.value = response.data;
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
        await getChnnelChatUser();
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
      getChnnelChatUser();
      channelChatUser.refresh();
      channels.refresh();
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
            member?.sentMessageCount = 0;
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
}
