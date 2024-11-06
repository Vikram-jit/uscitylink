import 'package:flutter/material.dart';
import 'package:uscitylink/utils/device/device_utility.dart';

class Messageui extends StatefulWidget {
  const Messageui({super.key});

  @override
  _MessageuiState createState() => _MessageuiState();
}

class _MessageuiState extends State<Messageui> {
  final TextEditingController _controller =
      TextEditingController(); // Text controller for the input field
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
      setState(() {
        messages.add(ChatMessage(
          sender: 'You',
          message: _controller.text,
          isUser: true,
          time: TimeOfDay.now().format(context),
        ));
        _controller.clear(); // Clear the input field after sending
      });
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
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(messages[index]);
                },
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
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
                        Icons.add,
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

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[200] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text(
                    message.time,
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

void main() {
  runApp(MaterialApp(
    home: Messageui(),
  ));
}
