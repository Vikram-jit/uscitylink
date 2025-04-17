import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uscitylink/constant.dart';
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
    if (socketService.isConnected.value) {
      socketService.socket.disconnect();
      socketService.isConnected.value = false;
    }
    super.dispose();
  }

  Future<void> queueMessage(MessageModel message) async {
    final box = await Constant.getQueueMessageBox();

    await box.add(message); // Stores message with auto key
    await box.close();
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

  void getChannelMessagesOldMethod(String channelId, int page,
      [String? driverPin]) async {
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
        loading.value = false;
      } else {
        loading.value = false;
        // print("Error: $error");
        // Utils.snackBar('Error', error.toString());
      }
    });
  }

  void getChannelMessages(String channelId, int page,
      [String? driverPin]) async {
    final box = await Hive.openBox(HiveBoxes.channelMessages);

    // Prevent refresh if already loading
    if (loading.value) return;

    // Set loading state to true
    loading.value = true;

    final String cacheKey = '${channelId}_$page';

    try {
      // ✅ Check if page is cached
      final cachedPage = (box.get(cacheKey) as List?)?.cast<MessageModel>();

      //Get the keys that start with channelId
      // This will help in determining the total pages

      final cachedKeys = box.keys
          .where((k) => k.toString().startsWith('${channelId}_'))
          .toList();
      if (cachedPage != null && cachedPage.isNotEmpty) {
        final cachedPages = cachedKeys
            .map((k) => int.tryParse(k.toString().split('_').last))
            .where((p) => p != null)
            .cast<int>()
            .toList()
          ..sort();

        if (cachedPages.isNotEmpty) {
          final int maxCachedPage = cachedPages.last;

          totalPages.value = maxCachedPage + 1;
        }

        if (page == 1) {
          messages.value = cachedPage;
        } else {
          messages.addAll(cachedPage);
        }
        print('Page $page loaded from cache ✅');
        currentPage.value = page;
        return;
      }

      // 🌐 Fetch from API if not cached
      final response = await __messageService.getChannelMessagesV2(
          channelId, page, driverPin);

      if (response.data.messages != null) {
        if (page == 1) {
          messages.value = response.data.messages!;
        } else {
          messages.addAll(response.data.messages!);
        }

        // 💾 Cache the fetched messages for this page
        await box.put(cacheKey, response.data.messages);

        if (response.data.pagination != null) {
          currentPage.value = response.data.pagination!.currentPage!;
          totalPages.value = response.data.pagination!.totalPages!;
        } else {
          print("Pagination data is missing in the response!");
        }
      }
    } catch (e) {
      // If offline, try to load from cache
      if (e.toString() == "Exception: No Internet Connection") {
        final cachedPage = (box.get(cacheKey) as List?)?.cast<MessageModel>();

        if (cachedPage != null && cachedPage.isNotEmpty) {
          if (page == 1) {
            messages.value = cachedPage;
          } else {
            messages.addAll(cachedPage);
          }
          print('Page $page loaded from cache (offline) 🔌');
        } else {
          print('No cached data for page $page');
        }
      }
      loading.value = false;
    } finally {
      // Set loading to false once done
      loading.value = false;
    }
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

    insertNewMessageCache(newMessage);
  }

  void addQueueNewMessage(dynamic data) async {
    MessageModel newMessage = MessageModel.fromJson(data);

    insertNewMessageCache(newMessage);
    if (socketService.isConnected.value) {
      socketService.socket
          .emit("update_message_status_queue", {"messageId": newMessage.id});
    }
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

  void updateUrlStatus(dynamic data) async {
    final messageId = data["messageId"];
    final channelId = data["channelId"];
    final tempId = data["tempId"];

    messages
        .where((message) => message.id == messageId)
        .forEach((message) => message.url_upload_type = data["status"]);

    if (tempId != "" || tempId != null) {
      await markUpdateMessageUrlStatus(channelId, messageId, data["status"]);
    }

    messages.refresh();
  }

  void deleteMessage(dynamic data) {
    final messageId = data;

    messages.removeWhere((message) => message.id == messageId);

    Utils.toastMessage("Deleted message successfully.");
    messages.refresh();
  }

  void updateSeenStatus(dynamic data) async {
    for (var message in messages) {
      if (message.senderId == data['userId']) {
        message.deliveryStatus = 'seen';
      }
    }
    messages.refresh();
    final box = await Hive.openBox(HiveBoxes.channelMessages);

    for (var key in box.keys) {
      if (key.toString().startsWith(data["channelId"])) {
        final messages = (box.get(key) as List?)?.cast<MessageModel>() ?? [];

        for (int i = 0; i < messages.length; i++) {
          if (messages[i].senderId == data['userId']) {
            messages[i].deliveryStatus = "seen"; // Update directly
            await box.put(key, messages); // Save updated list

            return;
          }
        }
      }
    }
  }

  void updateTypingStatus(dynamic data) {
    typing.value = data['typing'];
    typingMessage.value = data['message'];
  }

  Future<void> insertNewMessageCache(MessageModel message) async {
    final box = await Hive.openBox(HiveBoxes.channelMessages);
    const int messagesPerPage = 50;

    int currentPage = 1;
    String currentKey = '${channelId}_$currentPage';

    // Load or initialize page 1
    List<MessageModel> currentPageMessages =
        (box.get(currentKey) as List?)?.cast<MessageModel>() ?? [];

    // Insert the new message at the start
    currentPageMessages.insert(0, message);

    // Handle overflow
    List<MessageModel> overflow = [];

    if (currentPageMessages.length > messagesPerPage) {
      overflow = currentPageMessages.sublist(messagesPerPage);
      currentPageMessages = currentPageMessages.sublist(0, messagesPerPage);
    }

    await box.put(currentKey, currentPageMessages);

    // Update messages in UI for page 1
    if (currentPage == 1) {
      messages.value = currentPageMessages;
      messages.refresh();
    }

    // Propagate overflow to next pages
    while (overflow.isNotEmpty) {
      currentPage++;
      currentKey = '${channelId}_$currentPage';

      List<MessageModel> nextPageMessages =
          (box.get(currentKey) as List?)?.cast<MessageModel>() ?? [];

      nextPageMessages.insertAll(0, overflow);

      if (nextPageMessages.length > messagesPerPage) {
        overflow = nextPageMessages.sublist(messagesPerPage);
        nextPageMessages = nextPageMessages.sublist(0, messagesPerPage);
      } else {
        overflow = [];
      }

      await box.put(currentKey, nextPageMessages);
    }

    // Update total pages
    totalPages.value = currentPage;
  }

  Future<void> replaceMessageInCache(
      String channelId, String messageId, MessageModel newMessage) async {
    final box = await Hive.openBox<List<MessageModel>>(
        HiveBoxes.channelMessages); // Correct the type to List<MessageModel>

    // Retrieve all keys in the box that belong to this channel
    final keys =
        box.keys.where((key) => key.toString().startsWith(channelId)).toList();

    bool messageReplaced = false;

    // Iterate through all the pages in cache
    for (final key in keys) {
      final cachedPage = box.get(key) ?? [];

      if (cachedPage.isNotEmpty) {
        // Find the message by its ID
        for (int i = 0; i < cachedPage.length; i++) {
          if (cachedPage[i].id == messageId) {
            // Replace the message
            cachedPage[i] = newMessage;

            // Save the updated page back to the cache
            await box.put(key,
                cachedPage); // Now this correctly stores the updated list of messages
            print(
                'Message with id $messageId replaced on page ${key.toString().split('_').last}.');
            messageReplaced = true;
            break; // Stop searching once the message is replaced
          }
        }
      }

      if (messageReplaced) {
        break; // Exit the loop once the message has been replaced
      }
    }

    // If the message is not found after searching all pages
    if (!messageReplaced) {
      print('Message with id $messageId was not found in cache.');
    }
  }

  Future<void> markUpdateMessageUrlStatus(
      String channelId, String messageId, String status) async {
    final box = await Hive.openBox(HiveBoxes.channelMessages);

    for (var key in box.keys) {
      if (key.toString().startsWith(channelId)) {
        final messages = (box.get(key) as List?)?.cast<MessageModel>() ?? [];

        for (int i = 0; i < messages.length; i++) {
          if (messages[i].id == messageId) {
            messages[i].url_upload_type = status; // Update directly
            await box.put(key, messages); // Save updated list
            print('Marked message $messageId as seen in $key');
            return;
          }
        }
      }
    }

    print('Message $messageId not found in cache.');
  }
}
