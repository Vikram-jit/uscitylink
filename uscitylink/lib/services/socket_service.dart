import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/views/update_view.dart';

class SocketService extends GetxController {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  late IO.Socket socket;
  var pingResponse = "No pong received yet".obs;

  // Reactive state for message updates
  var message = "".obs;

  // Variable to track the connection state
  var isConnected = false.obs;

  // Reconnection state tracking
  var reconnectAttempts = 0.obs;
  var isReconnecting = false.obs;

  String generateSocketUrl(String token) {
    return 'http://52.9.12.189:4300?token=$token';
  }

  // Method to connect to the socket server
  Future<void> connectSocket() async {
    String? accessToken = await userPreferenceController.getToken();

    if (isConnected.value) {
      print("Already connected to socket.");
      return; // If already connected, don't try to connect again
    }
    String customUrl = generateSocketUrl(accessToken ?? "");

    // Establish socket connection with the access token as part of the query
    socket = IO.io(
      customUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNewConnection()
          .enableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    socket.on('connect', (_) async {
      print('Connected to socket server');
      reconnectAttempts.value = 0; // Reset reconnection attempts
      isConnected.value = true;
      startPing();
      sendQueueMessage();
    });

    socket.on('message', (data) {
      message.value = data; // Update message when new data is received
    });

    socket.on('update_queue_message_driver', (data) async {
      final String channelId = data["channelId"];
      final String oldMessageId = data["oldMessageId"];

      // Open the box as untyped
      final box = await Constant.getChannelMessagesBox();

      // Filter page keys like channelId_1, channelId_2 etc., skip channelId_pages
      final keys = box.keys
          .where((key) =>
              key.toString().startsWith('$channelId\_') &&
              !key.toString().endsWith('_pages'))
          .toList();

      bool messageReplaced = false;

      for (final key in keys) {
        final raw = box.get(key);
        if (raw is List) {
          List<MessageModel> cachedPage = raw
              .whereType<MessageModel>()
              .toList(); // Safely convert to MessageModel list

          for (int i = 0; i < cachedPage.length; i++) {
            if (cachedPage[i].id == oldMessageId) {
              final newMessage = MessageModel.fromJson(data["message"]);
              cachedPage[i] = newMessage;

              await box.put(key, cachedPage);
              print(
                  '✅ Message with id $oldMessageId replaced in cache key: $key');

              messageReplaced = true;

              // 🗑️ Remove from queue box
              final queueBox = await Constant.getQueueMessageBox();
              final matchingKey = queueBox.keys.firstWhere(
                  (k) => queueBox.get(k)?.id == oldMessageId,
                  orElse: () => null);

              if (matchingKey != null) {
                await queueBox.delete(matchingKey);
                await queueBox.close();
                print('🗑️ Removed message $oldMessageId from queue');
              }

              break;
            }
          }
        }

        if (messageReplaced) break;
      }
      if (Get.isRegistered<MessageController>()) {
        final messageController = Get.find<MessageController>();

        // final oldMessageId = data["oldMessageId"];
        final newMessage = MessageModel.fromJson(data["message"]);

        // Replace message in the in-memory list
        final index = messageController.messages
            .indexWhere((msg) => msg.id == oldMessageId);
        if (index != -1) {
          messageController.messages[index] = newMessage;
          messageController.messages.refresh(); // 🔁 Notify UI
          messageController.refresh(); // 🔁 Notify UI
        } else {
          print('⚠️ Message with id $oldMessageId not found in memory list');
          final queueBox = await Constant.getQueueMessageBox();
          final matchingKey = queueBox.keys.firstWhere(
              (k) => queueBox.get(k)?.id == oldMessageId,
              orElse: () => null);

          if (matchingKey != null) {
            await queueBox.delete(matchingKey);
            await queueBox.close();
            print('🗑️ Removed message $oldMessageId from queue');
          }
        }
      }
      if (!messageReplaced) {
        print('⚠️ Message with id $oldMessageId was not found in cache.');
        final queueBox = await Constant.getQueueMessageBox();
        final matchingKey = queueBox.keys.firstWhere(
            (k) => queueBox.get(k)?.id == oldMessageId,
            orElse: () => null);

        if (matchingKey != null) {
          await queueBox.delete(matchingKey);
          await queueBox.close();
          print('🗑️ Removed message $oldMessageId from queue');
        }
      }
    });
    socket.on('get_driver_messages_queues', (data) {
      print("📨 Queued messages received: $data");

      // Make sure data is a List
      if (data is List) {
        for (var item in data) {
          // Convert each message from JSON and push to UI
          if (Get.isRegistered<MessageController>()) {
            final message = MessageModel.fromJson(item);
            Get.find<MessageController>().addQueueNewMessage(message.toJson());
          }
        }
      } else {
        print("⚠️ Expected a List of messages but got: ${data.runtimeType}");
      }
    });
    socket.on('receive_message_channel', (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().onNewMessage(data);
      }
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().onNewMessage(data);
      }
      if (Get.isRegistered<ChannelController>()) {
        if (Get.find<ChannelController>().channels.isNotEmpty) {
          Get.find<ChannelController>().addNewMessage(data);
        }
      }
      if (Get.isRegistered<StaffchannelController>()) {
        if (Get.find<StaffchannelController>().channelChatUser.value.id !=
            null) {
          Get.find<StaffchannelController>().addNewMessage(data);
        }
      }
    });
    socket.on('update_file_upload_status', (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().updateUrlStatus(data);
      }
    });

    socket.on('update_file_upload_status_group', (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().updateUrlStatus(data);
      }
    });
    socket.on('update_file_sent_status', (data) {
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().updateUrlStatus(data);
      }
    });

    socket.on('update_file_recivied_status', (data) {
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().updateUrlStatus(data);
      }
    });

    socket.on('update_url_status_truck_group', (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().updateTruckUrlStatus(data);
      }
    });

    socket.on("new_message_count_update_staff", (data) {
      if (Get.find<StaffchannelController>().channelChatUser.value.id != null) {
        Get.find<StaffchannelController>().addNewMessageWithouIncrement(data);
      }
    });

    socket.on('update_user_channel_list', (data) {
      if (Get.find<ChannelController>().channels.isNotEmpty) {
        Get.find<ChannelController>().addNewMessage(data);
      }
    });

    socket.on('update_user_group_list', (data) {
      if (Get.isRegistered<GroupController>()) {
        // ✅ Check if it's registered
        final groupController = Get.find<GroupController>();

        if (groupController.groups.isNotEmpty) {
          groupController.addNewMessage(data);
        }
      }
    });

    socket.on('new_group_message_received', (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().onNewMessage(data);
      }
    });

    socket.on("receive_message_group", (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().onNewMessageToTruck(data);
      }
    });

    socket.on("user_added_to_channel", (data) {
      Get.find<ChannelController>().addNewChannel(data);
    });

    socket.on('user_added_to_group', (data) {
      Get.find<GroupController>().addNewGroup(data);
    });

    socket.on("update_channel_message_count", (data) {
      Get.find<ChannelController>().updateCount(data);
    });

    socket.on("new_message_count_update", (data) {
      Get.find<ChannelController>().incrementCount(data);
    });

    socket.on("update_all_message_seen", (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().updateSeenStatus(data);
      }
    });

    socket.on("user_online_driver", (data) {
      if (Get.isRegistered<StaffchannelController>()) {
        if (data != null) {
          String userId = data["userId"] ?? "";
          String channelId = data["channelId"] ?? "";
          bool isOnline = data["isOnline"] ?? false;
          Get.find<StaffchannelController>()
              .updateOnlineStatusMember(userId, channelId, isOnline);
        } else {
          print('Data is null');
        }
      }
    });

    socket.on("typingStaff", (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().updateTypingStatus(data);
      }
    });

    socket.on("typingStaff", (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().updateTypingStatus(data);
      }
    });
    socket.on("typingUser", (data) {
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().updateTypingStatus(data);
      }
    });
    socket.on("update_group_staff_message_count", (data) {
      if (Get.isRegistered<StaffgroupController>()) {
        Get.find<StaffgroupController>().updateGroupCount(data);
      }
    });

    socket.on("groupTypingRecive", (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().updateTypingStatus(data);
      }
    });
    socket.on("pin_done", (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().pinMessage(data);
      }
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().pinMessage(data);
      }
    });
    socket.on("delete_message", (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().deleteMessage(data);
      }
      if (Get.isRegistered<StaffchatController>()) {
        Get.find<StaffchatController>().deleteMessage(data);
      }
    });
    socket.on('pong', (_) {
      pingResponse.value = 'Pong received!';
      print('Received pong from server');
    });

    socket.on('UPDATE_APP_VERSION_INFO', (message) {
      print("update version $message");
      if (message == "NewVersion") {
        Get.offAll(() => UpdateView());
      }
    });

    socket.on('disconnect', (_) {
      print('Disconnected from socket server');
      isReconnecting.value = true; // Start tracking reconnection attempts
      isConnected.value = false; // Update connection status
    });

    socket.on('reconnect_attempt', (attempt) {
      reconnectAttempts.value = attempt;
      print('Reconnecting... Attempt $reconnectAttempts');
    });

    // Reconnected successfully
    socket.on('reconnect', (_) {
      print('Reconnected successfully');
      isConnected.value = true;
      isReconnecting.value = false;
    });

    // Reconnection failed
    socket.on('reconnect_failed', (_) {
      print('Reconnection failed');
      isReconnecting.value = false;
      // Optionally, notify user or handle failure
    });
  }

  void startPing() {
    if (isConnected.value) {
      // Use Timer.periodic to send the ping every 5 seconds
      Timer.periodic(const Duration(seconds: 10), (timer) {
        if (isConnected.value) {
          print('Sending ping...');
          socket.emit('ping'); // Send the ping message to the server
        } else {
          timer.cancel(); // Stop pinging if disconnected
        }
      });
    }
  }

  void sendQueueMessage() async {
    if (!isConnected.value) return;
    print("⏳ Sending queued messages in order...");

    final queueBox = await Constant.getQueueMessageBox();
    final channelBox = await Constant.getChannelMessagesBox();

    final List<MapEntry<dynamic, MessageModel>> sortedQueueEntries = queueBox
        .toMap()
        .entries
        .where((entry) => entry.value is MessageModel)
        .cast<MapEntry<dynamic, MessageModel>>()
        .toList()
      ..sort((a, b) => a.value.messageTimestampUtc!
          .compareTo(b.value.messageTimestampUtc!)); // Oldest first

    final List keysToRemove = [];

    for (var entry in sortedQueueEntries) {
      final key = entry.key;
      final queuedMessage = entry.value;

      // Update cached Hive message deliveryStatus
      final matchingKey = channelBox.keys.firstWhere(
        (k) =>
            k.toString().startsWith('${queuedMessage.channelId}_') &&
            k.toString().endsWith('_${queuedMessage.id}'),
        orElse: () => null,
      );

      if (matchingKey != null) {
        final message = channelBox.get(matchingKey);
        if (message is MessageModel) {
          message.deliveryStatus = "sending";
          await channelBox.put(matchingKey, message);
        }
      }

      // Update in-memory message list
      if (Get.isRegistered<MessageController>()) {
        final messageController = Get.find<MessageController>();
        final index = messageController.messages
            .indexWhere((msg) => msg.id == queuedMessage.id);

        if (index != -1) {
          messageController.messages[index].deliveryStatus = "sending";
          messageController.messages.refresh();
        }
      }

      // Emit to socket
      socket.emit("driver_message_queue", {
        "messageId": queuedMessage.id,
        "body": queuedMessage.body,
        "url": null,
        "channelId": queuedMessage.channelId,
        "thumbnail": null,
        "r_message_id": "",
        "messageTimestampUtc": queuedMessage.messageTimestampUtc
      });

      print('📤 Sent queued message: ${queuedMessage.id}');

      // Mark key for removal
      keysToRemove.add(key);
    }

    // 🗑️ Delete messages from queue after sending
    for (var key in keysToRemove) {
      await queueBox.delete(key);
      print('🗑️ Removed message from queue with key: $key');
    }
  }

  void sendQueueReMessage(String messageId) async {
    if (isConnected.value) {
      final box = await Constant.getQueueMessageBox();

      // Find the first message that matches the messageId
      final message = box.values.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => MessageModel(), // avoid crash if not found
      );

      if (message.id != null) {
        socket.emit("driver_message_queue_resend", {
          "messageId": message.id,
          "body": message.body,
          "url": null,
          "channelId": message.channelId,
          "thumbnail": null,
          "r_message_id": "",
        });

        print("Resent message with ID: ${message.id}");
      } else {
        print("Message with ID $messageId not found in queue.");
      }
    }
  }

  void getQueueMessage(String channelId) async {
    if (isConnected.value) {
      socket.emit("get_driver_message_queue", {"channelId": channelId});
    }
  }

  // Method to send a message to the server
  void sendMessage(String body, String? url, String? channelId,
      [String? thumbnail, String? r_message_id, String? url_upload_type]) {
    if (isConnected.value) {
      socket.emit("send_message_to_channel", {
        "body": body,
        "url": url,
        "channelId": channelId,
        "thumbnail": thumbnail,
        "r_message_id": r_message_id,
        "url_upload_type": url_upload_type
      });
    } else {
      print("Not connected to socket.");
    }
  }

  void pinMessage(String id, String value, String type) {
    print("${id} ${value} ${type}");
    if (isConnected.value) {
      socket
          .emit("pin_message", {"messageId": id, "value": value, "type": type});
    }
  }

  void deleteMessage(String id) {
    if (isConnected.value) {
      socket.emit("delete_message", {"messageId": id});
    }
  }

  void sendGroupMessage(
      String groupId, String channelId, String body, String? url,
      [String? thumbnail]) {
    if (isConnected.value) {
      socket.emit("send_group_message", {
        "groupId": groupId,
        "channelId": channelId,
        "body": body,
        "direction": "S",
        "url": url,
        "thumbnail": thumbnail
      });
    } else {
      print("Not connected to socket.");
    }
  }

  void removeFromGroup(String group_id) {
    if (isConnected.value) {
      socket.emit("user_removed_from_group", group_id);
      if (group_id.isNotEmpty) {
        socket.emit("user_removed_from_group", group_id);
      }
    } else {
      print("Not connected to socket.");
    }
  }

  void updateCountGroup(String group_id) {
    if (isConnected.value) {
      socket.emit("update_group_message_count", group_id);
      if (group_id.isNotEmpty) {
        socket.emit("update_group_message_count", group_id);
        socket.emit("update_group_staff_message_count_staff", group_id);
      }
    } else {
      print("Not connected to socket.");
    }
  }

  void updateActiveChannel(String channelId) async {
    if (isConnected.value) {
      socket.emit("driver_open_chat", channelId);
      if (channelId.isNotEmpty) {
        socket.emit("update_channel_message_count", channelId);
      }
    } else {
      // if (!isConnected.value) {
      //   socket.connect();
      // }
      //connectSocket();
      print("Not connected to socket 1.");
    }
  }

  void addUserToGroup(String channelId, String groupId) {
    if (isConnected.value) {
      socket.emit(
          "group_user_add", {"channel_id": channelId, "group_id": groupId});
    } else {
      print("Not connected to socket.");
    }
  }

  void sendPing() {
    if (isConnected.value) {
      print('Sending ping...');
      socket.emit('ping');
    } else {
      print('Not connected to socket');
    }
  }

  //staff  socket

  void switchStaffChannel(String channelId) {
    socket.emit("staff_channel_update", channelId);
  }

  void updateStaffActiveUserChat(String userId) {
    socket.emit("staff_open_chat", userId);
  }

  void updateStaffGroup(String groupId) {
    socket.emit("update_group_staff_message_count", groupId);
  }

  void sendMessageToUser(String userId, String body, String? url,
      [String? thumbnail, String? r_message_id]) {
    if (isConnected.value) {
      socket.emit("send_message_to_user", {
        "userId": userId,
        "body": body,
        "direction": "S",
        "url": url,
        "thumbnail": thumbnail,
        "r_message_id": r_message_id
      });
    } else {
      print("Not connected to socket.");
    }
  }

  void sendMessageToTruck(
      String userId, String groupId, String body, String? url,
      [String? thumbnail]) {
    if (isConnected.value) {
      socket.emit("send_message_to_user_by_group", {
        "userId": userId,
        "groupId": groupId,
        "body": body,
        "direction": "S",
        "url": url,
        "thumbnail": thumbnail
      });
    } else {
      print("Not connected to socket.");
    }
  }

  void staffTyping(String userId, bool isTyping) {
    if (isConnected.value) {
      socket.emit("typing", {"userId": userId, "isTyping": isTyping});
    }
  }

  void staffUnreadAllUserMessage(String? channelId, String? userId) {
    if (isConnected.value) {
      socket.emit("update_channel_sent_message_count",
          {"channelId": channelId, "userId": userId});
      if (Get.find<StaffchannelController>().channelChatUser.value.id != null) {
        Get.find<StaffchannelController>().updateCount(channelId!, userId!);
      }
    }
  }

  void checkVersion() async {
    if (isConnected.value) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      AppUpdateInfo appData = AppUpdateInfo(
          buildNumber: packageInfo.buildNumber,
          version: packageInfo.version,
          platform: Platform.operatingSystem);
      socket.emit("UPDATE_APP_VERSION", appData);
    } else {
      socket.connect();
    }
  }
  // void staffListeningDriverTyping(String userId, bool isTyping) {
  //   if (isConnected.value) {
  //     socket.on("typing", {"userId": userId, "isTyping": isTyping});
  //   }
  // }

  void logout() {
    if (isConnected.value) {
      socket.emit("logout");
      socket.disconnect();
    } else {
      print("Not connected to socket.");
    }
  }

  @override
  void onClose() {
    print("SocketService: Closing and disconnecting socket.");
    if (socket.connected) {
      socket.disconnect();
    }
    super.onClose(); // Always call super.onClose() after cleanup
  }
}
