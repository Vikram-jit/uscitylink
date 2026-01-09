import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/driver_chat/widgets/driver_list_sidebar.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/chat_header.dart';
import 'package:chat_app/modules/home/desktop/widgets/left_sidebar.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_input.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_list.dart';
import 'package:chat_app/modules/home/home_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopView extends StatelessWidget {
  DesktopView({super.key});
  final controller = Get.find<HomeController>();
  final msgController = Get.find<MessageController>();
  final searchCtrl = Get.find<GlobalSearchController>();
  final searchKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => searchCtrl.hideOverlay(),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              height: 40,
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: SizedBox(
                          height: 30,
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextField(
                            key: searchKey,
                            onChanged: (value) => searchCtrl.onSearchChanged(
                              value,
                              context,
                              searchKey,
                            ),
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
                    ],
                  ),
                  Spacer(),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.help_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 4.0, right: 4.0),
                child: Row(
                  children: [
                    LeftSidebar(),
                    DriverListSidebar(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.68,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Obx(() {
                          if (controller.driverId.isEmpty)
                            return Center(child: Text("Select Chat"));
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
                                        return Text(
                                          "Files",
                                        ); // Files Tab Content
                                      case 2:
                                        return Text("Pins"); // Pins Tab Content
                                      default:
                                        return MessageList();
                                    }
                                  }),
                                ),

                                if (msgController.isTyping.value)
                                  Align(
                                    alignment: AlignmentGeometry.topLeft,
                                    child: Container(
                                      margin: EdgeInsets.only(left: 10),
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
                                if (msgController.currentTab.value ==
                                    0) // DM Message List
                                  MessageInput(),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
