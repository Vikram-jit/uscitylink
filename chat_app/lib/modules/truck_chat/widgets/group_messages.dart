import 'package:chat_app/modules/home/views/MessageBubble.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:chat_app/widgets/date_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupMessages extends StatelessWidget {
  GroupMessages({super.key});

  final controller = Get.find<GroupMessageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.messages.isEmpty && controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final messages = controller.messages;
      final hasMore = controller.hasMore.value;

      return ListView.builder(
        controller: controller.scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final message = messages[index];
          final prevMessage = index + 1 < messages.length
              ? messages[index + 1]
              : null;

          final bool showDateDivider =
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
                driverNumber: message.sender?.user?.driverNumber ?? "-",
                thumbnail: message.thumbnail,
                mediaUrl: message.url,
                uploadType: message.urlUploadType,
                name: message.sender?.username ?? "",
                time: _formatTime(_parseDate(message.messageTimestampUtc)),
                message: message.body ?? "",
                isMe: message.messageDirection == "R",
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
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
