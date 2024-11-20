import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/events/socket_events.dart';

class SocketService extends GetxController {
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  late IO.Socket socket;

  // Reactive state for message updates
  var message = "".obs;

  // Variable to track the connection state
  var isConnected = false.obs;

  String generateSocketUrl(String token) {
    return 'http://52.8.75.98:4300?token=$token';
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
          .build(),
    );

    socket.on('connect', (_) {
      print('Connected to socket server');
      isConnected.value = true;
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

    socket.on("user_added_to_channel", (data) {
      Get.find<ChannelController>().addNewChannel(data);
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

    socket.on('disconnect', (_) {
      print('Disconnected from socket server');
      isConnected.value = false; // Update connection status
    });
  }

  // Method to send a message to the server
  void sendMessage(String body, String? url) {
    if (isConnected.value) {
      socket.emit("send_message_to_channel", {"body": body, "url": url});
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
    socket.dispose();
    super.onClose();
  }
}
