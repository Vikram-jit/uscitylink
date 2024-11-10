import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class Messageui extends StatefulWidget {
  final dynamic channelId;
  Messageui({required this.channelId, super.key});

  @override
  _MessageuiState createState() => _MessageuiState();
}

class _MessageuiState extends State<Messageui> {
  final TextEditingController _controller = TextEditingController();

  MessageController messageController = Get.put(MessageController());
  SocketService socketService = Get.put(SocketService());
  final List<ChatMessage> messages = [
    ChatMessage(
      sender: 'John',
      message: 'Hello, how are you?',
      isUser: false,
      time: '10:00 AM',
    ),
    ChatMessage(
      sender: 'You',
      message: 'I\'m good, thanks! How about you?',
      isUser: true,
      time: '10:01 AM',
    ),
    ChatMessage(
      sender: 'John',
      message: 'I\'m doing great, thanks for asking!',
      isUser: false,
      time: '10:02 AM',
    ),
    ChatMessage(
      sender: 'You',
      message: 'That\'s awesome! Let\'s catch up soon.',
      isUser: true,
      time: '10:05 AM',
    ),
    // More sample messages
  ];

  String lastLogin = 'Last login: 8:30 AM, 1st Dec 2024'; // Sample last login
  String channelName = 'Chat Channel 1'; // Sample channel name

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.sendMessage(_controller.text);
      _controller.clear();
      // setState(() {
      //   messages.add(ChatMessage(
      //     sender: 'You',
      //     message: _controller.text,
      //     isUser: true,
      //     time: TimeOfDay.now().format(context),
      //   ));
      //   _controller.clear(); // Clear the input field after sending
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channelName, // Display the channel name
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    lastLogin, // Display the last login info
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(TDeviceUtils.getAppBarHeight() * 0.4),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  print("hello");
                },
                child: Obx(() {
                  if (messageController.messages.isEmpty) {
                    return CircularProgressIndicator();
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: messageController.messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatMessage(
                          messageController.messages[index]);
                    },
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Text Field for typing the message
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Plus button to send the message
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(MessageModel message) {
    return Align(
      alignment: message.messageDirection == "R"
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.messageDirection == "R"
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.messageDirection == "R"
                    ? Colors.blue[200]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.messageDirection == "R"
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body!,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    message.messageTimestampUtc!,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String message;
  final bool isUser;
  final String time;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.isUser,
    required this.time,
  });
}
