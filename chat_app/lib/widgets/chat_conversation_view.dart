import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/chat_header.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_input.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_list.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatConversationView extends StatelessWidget {
  final HomeController controller;
  final MessageController msgController;

  const ChatConversationView({
    super.key,
    required this.controller,
    required this.msgController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ChatHeader(userName: controller.selectedName.value),

          Expanded(
            child: Obx(() {
              switch (msgController.currentTab.value) {
                case 0:
                  return MessageList();
                case 1:
                  return const Center(child: Text("Files"));
                case 2:
                  return const Center(child: Text("Pins"));
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

          if (msgController.currentTab.value == 0) MessageInput(),
        ],
      ),
    );
  }
}
