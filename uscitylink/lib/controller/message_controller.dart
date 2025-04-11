import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/hive_boxes.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/message_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';

class MessageController extends GetxController {
  SocketService socketService = Get.find<SocketService>();
  var messages = <MessageModel>[].obs;
  var typing = false.obs;
  var typingMessage = "".obs;
  final __messageService = MessageService();
  var currentIndex = 0.obs;
  var channelId = "".obs;
  var name = "".obs;
  var selectedRplyMessage = MessageModel().obs;
  var isTyping = false.obs;
  // Timer for typing timeout
  Timer? typingTimer;
  late DateTime typingStartTime;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var loading = false.obs;

  @override
  void onInit() {
    super.onInit();

    Map args = Get.arguments as Map? ?? {};

    channelId.value = args['channelId'] ?? '';
    if (channelId.isNotEmpty) {
      getChannelMessages(channelId.value, currentPage.value);
    } else {
      print("Error: channelId is empty or invalid.");
    }
  }

  @override
  void dispose() {
    print("GroupController is being disposed. Disconnecting socket...");
    if (socketService.isConnected.value) {
      socketService.socket.disconnect();
      socketService.isConnected.value = false;
    }
    super.dispose();
  }

// Start typing event
  void startTyping(String channelId) {
    if (typingTimer != null && typingTimer!.isActive) {
      typingTimer!.cancel();
    }

    isTyping.value = true;
    socketService.socket
        .emit('driverTyping', {'isTyping': true, "channelId": channelId});

    typingStartTime = DateTime.now();

    // Stop typing after 1.5 seconds of inactivity
    typingTimer = Timer(const Duration(seconds: 1), () {
      if (DateTime.now().difference(typingStartTime).inSeconds >= 1) {
        stopTyping(channelId);
      }
    });
  }

  // Stop typing event
  void stopTyping(String channelId) {
    isTyping.value = false;
    socketService.socket
        .emit('driverTyping', {'isTyping': false, "channelId": channelId});
  }

  void getChannelMessages(String channelId, int page,
      [String? driverPin]) async {
    Box channelMessagesBox = await Hive.openBox(HiveBoxes.channelMessages);

    // Prevent refresh if already loading
    if (loading.value) return;

    // Set loading state to true
    loading.value = true;

    __messageService
        .getChannelMessagesV2(channelId, page, driverPin)
        .then((response) async {
      if (page > 1) {
        if (response.data.messages != null) {
          messages.addAll(response.data.messages ?? []);
        }
      } else {
        if (response.data.messages != null) {
          messages.value = response.data.messages ?? [];
          await channelMessagesBox.put(
              HiveBoxes.channelMessages, response.data.messages);
        }
      }

      if (response.data.pagination != null) {
        currentPage.value = response.data.pagination!.currentPage!;
        totalPages.value = response.data.pagination!.totalPages!;
      } else {
        print("Pagination data is missing in the response!");
      }

      socketService.updateActiveChannel(channelId);
      // Set loading state to true
      loading.value = false;
    }).onError((error, stackTrace) {
      if (error.toString() == "Exception: No Internet Connection") {
        final cachedList = channelMessagesBox.get(HiveBoxes.channelMessages);

        // Convert safely
        List<MessageModel>? cachedMessages =
            (cachedList as List?)?.cast<MessageModel>();

        if (cachedMessages != null) {
          messages.value = cachedMessages;
        }

        loading.value = false;
      } else {
        loading.value = false;
        print("Error: $error");
        Utils.snackBar('Error', error.toString());
      }
    });
  }

  void updateChannelMessagesByNotification(
      String newChannelId, String channelName) {
    Get.back();
    Get.toNamed(
      AppRoutes.driverMessage,
      arguments: {'channelId': newChannelId, 'name': channelName},
    );
    channelId.value = newChannelId;
    name.value = channelName;

    messages.clear();

    __messageService.getChannelMessages(newChannelId).then((response) {
      messages.value = response.data;
      socketService.updateActiveChannel(newChannelId);
    }).onError((error, stackTrace) {
      print('Error: $error');
      Utils.snackBar('Error', error.toString());
    });
  }

  void onNewMessage(dynamic data) {
    MessageModel newMessage = MessageModel.fromJson(data);

    messages.insert(0, newMessage);
    messages.refresh();
  }

  void pinMessage(dynamic data) {
    final messageId = data[0];

    messages
        .where((message) => message.id == messageId)
        .forEach((message) => message.driverPin = data[1]);
    Utils.toastMessage(
        "${data[1] == "1" ? "pin" : "un-pin"} message successfully");
    messages.refresh();
  }

  void updateUrlStatus(dynamic data) {
    final messageId = data["messageId"];
    messages
        .where((message) => message.id == messageId)
        .forEach((message) => message.url_upload_type = data["status"]);

    messages.refresh();
  }

  void deleteMessage(dynamic data) {
    final messageId = data;

    messages.removeWhere((message) => message.id == messageId);

    Utils.toastMessage("Deleted message successfully.");
    messages.refresh();
  }

  void updateSeenStatus(dynamic data) {
    for (var message in messages) {
      if (message.senderId == data['userId']) {
        message.deliveryStatus = 'seen';
      }
    }

    messages.refresh();
  }

  void updateTypingStatus(dynamic data) {
    typing.value = data['typing'];
    typingMessage.value = data['message'];
  }
}
