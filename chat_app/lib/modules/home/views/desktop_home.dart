import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/channel_sidebar.dart';
import 'package:chat_app/modules/home/desktop/widgets/chat_header.dart';
import 'package:chat_app/modules/home/desktop/widgets/left_sidebar.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_input.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_list.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopHomeView extends StatelessWidget {
  DesktopHomeView({super.key});
  final controller = Get.find<HomeController>();
  final msgController = Get.find<MessageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 40,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Container(
              margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.1,
              ),
              child: SizedBox(
                height: 30,
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextField(
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ), // text black
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(
                      alpha: 0.30,
                    ), // white box
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 18,
                    ),
                    hintText: "Search...",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ), // grey hint
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: 20,
              height: 20,
              child: Icon(Icons.help_outlined, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 4.0, right: 4.0),
        child: Row(
          children: [
            LeftSidebar(),
            ChannelSidebar(),
            Expanded(
              child: Obx(() {
                print(controller.currentView.value);
                switch (controller.currentView.value) {
                  case SidebarViewType.directMessage:
                    return Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          ChatHeader(
                            userName: controller.selectedName.value,
                          ), // DM Header
                          Expanded(
                            child: Obx(() {
                              switch (msgController.currentTab.value) {
                                case 0:
                                  return MessageList(); // Messages
                                case 1:
                                  return Text("Files"); // Files Tab Content
                                case 2:
                                  return Text("Pins"); // Pins Tab Content
                                default:
                                  return MessageList();
                              }
                            }),
                          ),
                          if (msgController.currentTab.value ==
                              0) // DM Message List
                            MessageInput(),
                        ],
                      ),
                    );

                  case SidebarViewType.channel:
                    return Container(
                      color: Colors.white,
                      child: Column(children: [
                         
                        ],
                      ),
                    );

                  case SidebarViewType.directory:
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          "📁 Directories View Coming Soon",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
