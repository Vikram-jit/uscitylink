import 'package:chat_app/modules/home/controllers/forward_message_controller.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/forward_message_dialog.dart';
import 'package:chat_app/modules/home/views/MessageBubble.dart';
import 'package:chat_app/widgets/date_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late final MessageController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.find<MessageController>();
  }

  @override
  void dispose() {
    // Detach cleanly when this widget leaves the tree
    // so the controller's scrollController has no stale attachment

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_c.messages.isEmpty && _c.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        // ── Always use the getter — returns a fresh controller
        //    if the previous one was disposed ──
        controller: _c.scrollController,
        reverse: true,
        itemCount: _c.messages.length + (_c.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _c.messages.length) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final message = _c.messages[index];
          final prevMessage = index + 1 < _c.messages.length
              ? _c.messages[index + 1]
              : null;

          final showDateDivider =
              prevMessage == null ||
              !_isSameDay(
                _parseDate(message.messageTimestampUtc),
                _parseDate(prevMessage.messageTimestampUtc),
              );

          return Column(
            children: [
              if (showDateDivider)
                DateDivider(date: _parseDate(message.messageTimestampUtc)),
              MessageBubble(
                id: message.id!,
                driverNumber: message.sender?.user?.driverNumber ?? '-',
                thumbnail: message.thumbnail,
                mediaUrl: message.url,
                uploadType: message.urlUploadType,
                name: message.sender?.username ?? '',
                time: _formatTime(_parseDate(message.messageTimestampUtc)),
                message: message.body ?? '',
                isMe: message.messageDirection == 'R',
                onReply: () => _c.selectMessageReply.value = message,
                replyMessage: message.rMessage,
                staffPin: message.staffPin ?? '',
                onPin: () =>
                    _c.pinMessage(message.id!, message.staffPin ?? '0'),
                onDelete: () => _c.deleteMessage(message.id!),
                onForward: () {
                  if (!Get.isRegistered<ForwardMessageController>(
                    tag: 'forward',
                  )) {
                    Get.put(ForwardMessageController(), tag: 'forward');
                  }
                  Get.dialog(ForwardMessageDialog(message: message)).then((_) {
                    Get.delete<ForwardMessageController>(tag: 'forward');
                  });
                },
              ),
            ],
          );
        },
      );
    });
  }

  DateTime _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.parse(value).toLocal();
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
