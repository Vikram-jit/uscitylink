import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/model/message_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';

class Messageui extends StatefulWidget {
  final dynamic channelId;
  final String name;
  Messageui({required this.channelId, super.key, required this.name});

  @override
  _MessageuiState createState() => _MessageuiState();
}

class _MessageuiState extends State<Messageui> {
  final TextEditingController _controller = TextEditingController();

  late MessageController messageController;
  SocketService socketService = Get.put(SocketService());
  @override
  void initState() {
    super.initState();

    // Initialize the MessageController and fetch messages for the given channelId
    messageController = Get.put(MessageController());
    messageController.getChannelMessages(
        widget.channelId); // Fetch the messages for the given channelId
  }

  // Function to send a new message
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      socketService.sendMessage(_controller.text);
      _controller.clear();
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
                    widget.name, // Display the channel name
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  // Text(
                  //   lastLogin, // Display the last login info
                  //   style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  // ),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back), // Back icon
                onPressed: () {
                  // Trigger the socket event when the back icon is clicked
                  socketService.updateActiveChannel("");
                  Navigator.pop(
                      context); // This will pop the current screen and go back to the previous screen
                },
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
                  messageController.getChannelMessages(widget.channelId);
                },
                child: Obx(() {
                  if (messageController.messages.isEmpty) {
                    return Center(
                        child: Container(
                      height: 100,
                      width: 100,
                      child: InkWell(
                        onTap: () {
                          socketService.sendMessage("Hi");
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              color: Colors.orange,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text("Say Hi",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey.shade700))
                          ],
                        ),
                      ),
                    ));
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    Utils.formatUtcDateTime(message.messageTimestampUtc!),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
