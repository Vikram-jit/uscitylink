import 'dart:convert';

import 'package:get/get.dart';
import 'package:uscitylink/model/staff/user_message_model.dart';
import 'package:uscitylink/services/staff_services/chat_service.dart';
import 'package:uscitylink/utils/utils.dart';

class StaffchatController {
  var message = UserMessageModel().obs;

  final __channelService = ChatService();

  var loading = false.obs;

  Future<void> getChannelMembers(String id) async {
    loading.value = true;

    try {
      var response = await __channelService.getMesssageByUserId(id);
      message.value = response.data;
      loading.value = false;
    } catch (error) {
      loading.value = false;
      Utils.snackBar('Error', error.toString());
    } finally {
      loading.value = false;
    }
  }
}
