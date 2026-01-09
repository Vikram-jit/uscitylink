import 'package:chat_app/core/controller/global_search_controller.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/desktop/components/overview_screen.dart';
import 'package:chat_app/modules/home/desktop/widgets/channel_sidebar.dart';
import 'package:chat_app/modules/home/desktop/widgets/chat_header.dart';
import 'package:chat_app/modules/home/desktop/widgets/left_sidebar.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_input.dart';
import 'package:chat_app/modules/home/desktop/widgets/message_list.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/home/screens/channel_memmbers_screen.dart';
import 'package:chat_app/modules/home/screens/channel_screen.dart';
import 'package:chat_app/modules/home/screens/driver_screen.dart';
import 'package:chat_app/modules/home/screens/template_screen.dart';
import 'package:chat_app/modules/home/screens/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopHomeView extends StatelessWidget {
  DesktopHomeView({super.key});
  final controller = Get.find<HomeController>();
  final msgController = Get.find<MessageController>();
  final overviewController = Get.find<OverviewController>();
  final searchCtrl = Get.find<GlobalSearchController>();
  final searchKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                  key: searchKey,
                  onChanged: (value) =>
                      searchCtrl.onSearchChanged(value, context, searchKey),
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
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.68,
              child: Obx(() {
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

                  case SidebarViewType.channel:
                    return ChannelScreen();
                  case SidebarViewType.driver:
                    return DriverScreen();
                  case SidebarViewType.users:
                    return UserScreen();
                  case SidebarViewType.template:
                    return TemplateScreen();
                  case SidebarViewType.channelMembers:
                    return ChannelMemmbersScreen();
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

                  case SidebarViewType.home:
                    return Obx(() {
                      if (overviewController.isLoading.value) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(6.0),
                              bottomRight: Radius.circular(6.0),
                            ),
                          ),

                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      return OverviewScreen(
                        totalMessages:
                            overviewController.overview.value.messageCount ?? 0,
                        unreadMessages:
                            overviewController.overview.value.userUnMessage ??
                            0,
                        channels:
                            overviewController.overview.value.channelCount ?? 0,
                        trucksGroups:
                            overviewController.overview.value.truckGroupCount ??
                            0,
                        driverCount:
                            overviewController.overview.value.driverCount ?? 0,
                        drivers:
                            overviewController.overview.value.lastFiveDriver ??
                            [],
                      );
                    });
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
