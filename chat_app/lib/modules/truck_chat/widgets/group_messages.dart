import 'package:chat_app/modules/home/controllers/forward_message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/forward_message_dialog.dart';
import 'package:chat_app/modules/home/views/MessageBubble.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:chat_app/widgets/date_divider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupMessages extends StatefulWidget {
  const GroupMessages({super.key});

  @override
  State<GroupMessages> createState() => _GroupMessagesState();
}

class _GroupMessagesState extends State<GroupMessages> {
  final controller = Get.find<GroupMessageController>();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 50 &&
        !controller.isLoading.value &&
        controller.hasMore.value) {
      controller.loadMoreForCurrentGroup(
        controller.currentTab.value == 2 ? "1" : "0",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.messages.isEmpty && controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final messages = controller.messages;
      final hasMore = controller.hasMore.value;

      if (messages.isEmpty) {
        return const Center(
          child: Text(
            "No chat yet",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
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
                id: message.id!,
                driverNumber: message.sender?.user?.driverNumber ?? "-",
                thumbnail: message.thumbnail,
                mediaUrl: message.url,
                uploadType: message.urlUploadType,
                name: message.sender?.username ?? "",
                time: _formatTime(_parseDate(message.messageTimestampUtc)),
                message: message.body ?? "",
                isMe: message.messageDirection == "R",
                replyMessage: message.rMessage,
                staffPin: message.staffPin ?? "",
                onPin: () =>
                    controller.pinMessage(message.id!, message.staffPin ?? "0"),
                onReply: () => controller.selectMessageReply.value = message,
                onDelete: () => controller.deleteMessage(message.id!),
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
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
