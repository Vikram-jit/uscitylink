// ignore_for_file: unnecessary_set_literal

import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/model/staff/channel_chat_user_model.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/channel_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/services/staff_services/channel_service.dart';
import 'package:uscitylink/utils/utils.dart';

class StaffchannelController extends GetxController {
  var channels = <ChannelModel>[].obs;
  var channelMebers = <ChannelMemberModel>[].obs;
  var drivers = <DriverModel>[].obs;
  var loading = false.obs;
  var selectedDriversIds = <String>[].obs;
  var channelChatUser = ChannelChatUserModel().obs;
  final __channelService = ChannelService();

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
