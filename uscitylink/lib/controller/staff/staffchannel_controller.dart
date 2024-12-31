// ignore_for_file: unnecessary_set_literal

import 'package:get/get.dart';
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
    loading.value = true; // Start loading

    try {
      // Call your API and await the result
      var response = await __channelService.getStaffChannelMember();
      channelMebers.value = response.data;
    } catch (error) {
      // Handle any errors
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value =
          false; // Stop loading whether the API call was successful or not
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

  void addMemberIntoChannel(String id, bool value) {
    loading.value = true;
    var index = drivers.indexWhere((member) => member.id == id);
    if (index.isNegative == false) {
      drivers[index].isChannelExist = value;

      if (value) {
        selectedDriversIds.add(drivers[index]!.profiles![0].id!);
      } else {
        selectedDriversIds.remove(id);
      }

      drivers.refresh();
      loading.value = false;
    }
    loading.value = false;
  }
}
