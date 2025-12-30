import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../views/MessageBubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: const [
        MessageBubble(
          name: "John",
          time: "2:30 PM",
          message: "Hello team! How is the project going?",
          isMe: false,
        ),
        MessageBubble(
          name: "John",
          time: "2:30 PM",
          message: "Hello team! How is the project going?",
          isMe: false,
        ),
        MessageBubble(
          name: "John",
          time: "2:30 PM",
          message: "Hello team! How is the project going?",
          isMe: true,
        ),
      ],
    );
  }
}
