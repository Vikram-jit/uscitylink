import 'dart:async';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';

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
    return 'http://localhost:4300?token=$token';
  }

  // Method to connect to the socket server
  Future<void> connectSocket() async {
    String? accessToken = await userPreferenceController.getToken();

    if (accessToken == null) {
      print("No access token found. Please log in.");
      return; // Token is missing or user is not logged in
    }

    if (isConnected.value) {
      print("Already connected to socket.");
      return; // If already connected, don't try to connect again
    }
    String customUrl = generateSocketUrl(accessToken);

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

    socket.on('connect', (_) {
      print('Connected to socket server');
      reconnectAttempts.value = 0; // Reset reconnection attempts
      isConnected.value = true;
      startPing();
    });

    socket.on('message', (data) {
      message.value = data; // Update message when new data is received
    });

    socket.on('receive_message_channel', (data) {
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().onNewMessage(data);
      }

      if (Get.find<ChannelController>().channels.isNotEmpty) {
        Get.find<ChannelController>().addNewMessage(data);
      }
    });

    socket.on('update_user_channel_list', (data) {
      if (Get.find<ChannelController>().channels.isNotEmpty) {
        Get.find<ChannelController>().addNewMessage(data);
      }
    });

    socket.on('update_user_group_list', (data) {
      if (Get.find<GroupController>().groups.isNotEmpty) {
        Get.find<GroupController>().addNewMessage(data);
      }
    });

    socket.on('new_group_message_received', (data) {
      if (Get.isRegistered<GroupController>()) {
        Get.find<GroupController>().onNewMessage(data);
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

    socket.on("typingStaff", (data) {
      print(data);
      if (Get.isRegistered<MessageController>()) {
        Get.find<MessageController>().updateTypingStatus(data);
      }
    });
    socket.on('pong', (_) {
      pingResponse.value = 'Pong received!';
      print('Received pong from server');
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

  // Method to send a message to the server
  void sendMessage(String body, String? url, String? channelId) {
    if (isConnected.value) {
      socket.emit("send_message_to_channel",
          {"body": body, "url": url, "channelId": channelId});
    } else {
      print("Not connected to socket.");
    }
  }

  void sendGroupMessage(
      String groupId, String channelId, String body, String? url) {
    if (isConnected.value) {
      socket.emit("send_group_message", {
        "groupId": groupId,
        "channelId": channelId,
        "body": body,
        "direction": "S",
        "url": url,
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
      }
    } else {
      print("Not connected to socket.");
    }
  }

  void updateActiveChannel(String channelId) {
    if (isConnected.value) {
      socket.emit("driver_open_chat", channelId);
      if (channelId.isNotEmpty) {
        socket.emit("update_channel_message_count", channelId);
      }
    } else {
      print("Not connected to socket.");
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
