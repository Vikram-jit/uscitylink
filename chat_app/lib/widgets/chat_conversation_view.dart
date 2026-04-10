import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/chat_header.dart';
import 'package:chat_app/modules/home/desktop/widgets/media_gallery.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_input.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_list.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:chat_app/modules/truck_chat/widgets/group_detail_view.dart';
import 'package:chat_app/modules/truck_chat/widgets/group_header.dart';
import 'package:chat_app/modules/truck_chat/widgets/group_input.dart';
import 'package:chat_app/modules/truck_chat/widgets/group_messages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatConversationView extends StatelessWidget {
  final String type;
  final HomeController controller;
  final MessageController msgController;
  final GroupMessageController groupMsgController;

  const ChatConversationView({
    super.key,
    required this.type,
    required this.controller,
    required this.msgController,
    required this.groupMsgController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: type == "driver"
          ? Column(
              children: [
                ChatHeader(),
                Expanded(
                  child: Obx(() {
                    switch (msgController.currentTab.value) {
                      case 0:
                        return MessageList();
                      case 1:
                        return MediaGallery(
                          source: MediaGallerySource.channel,
                        ); // Files Tab Content
                      case 2:
                        return MessageList();
                      default:
                        return MessageList();
                    }
                  }),
                ),

                if (msgController.isTyping.value)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Text(
                        msgController.typingMsg.value,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                if (msgController.currentTab.value == 0)
                  MessageInput(isPinMessage: 0),
              ],
            )
          : Column(
              children: [
                GroupHeader(userName: controller.selectedName.value),
                Expanded(
                  child: Obx(() {
                    if (groupMsgController.showDetails.value) {
                      return GroupDetailView();
                    }

                    switch (groupMsgController.currentTab.value) {
                      case 0:
                        return GroupMessages();
                      case 1:
                        return MediaGallery(source: MediaGallerySource.group);
                      case 2:
                        return GroupMessages();
                      default:
                        return GroupMessages();
                    }
                  }),
                ),
                if (groupMsgController.isTyping.value)
                  Text(groupMsgController.typingMsg.value),
                if (msgController.currentTab.value == 0) // DM Message List
                  GroupInput(),
              ],
            ),
    );
  }
}
