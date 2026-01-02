import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/desktop/components/channel_tile.dart';
import 'package:chat_app/modules/home/desktop/components/user_status_tile.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/spacing.dart';

class ChannelSidebar extends StatefulWidget {
  const ChannelSidebar({super.key});

  @override
  State<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends State<ChannelSidebar> {
  bool channelsOpen = true;
  bool dmOpen = true;
  bool tOpen = true;
  OverviewController _overviewController = Get.find<OverviewController>();
  HomeController _homeController = Get.find<HomeController>();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      decoration: BoxDecoration(
        color: AppColors.channelSideColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      child: Text("US CITY LINK", style: TStyle.channelTitle),
                      onTap: () {
                        _homeController.currentView.value =
                            SidebarViewType.home;
                        _homeController.selectedName.value = "";
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // 🔹 Body Content Scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              children: [
                // ==================== CHANNELS ====================
                _sectionHeader(
                  "Channels",
                  channelsOpen,
                  () => setState(() => channelsOpen = !channelsOpen),
                ),

                if (channelsOpen) ...[
                  ChannelTile(
                    "Channels",
                    icon: Icons.ac_unit,
                    sidebarViewType: SidebarViewType.channel,
                  ),
                  ChannelTile(
                    "Channel Memmbers",
                    icon: Icons.groups,
                    sidebarViewType: SidebarViewType.channelMembers,
                  ),
                  ChannelTile(
                    "Templates",
                    icon: Icons.brush,
                    sidebarViewType: SidebarViewType.template,
                  ),
                  //ChannelTile("Users", icon: Icons.person_off),
                  ChannelTile(
                    "Drivers",
                    icon: Icons.drive_eta,
                    sidebarViewType: SidebarViewType.driver,
                  ),
                  ChannelTile(
                    "Users",
                    icon: Icons.person,
                    sidebarViewType: SidebarViewType.users,
                  ),
                  // ChannelTile("Announcements", icon: Icons.campaign),
                ],

                const SizedBox(height: 10),

                // ==================== DIRECT MESSAGES ====================
                Obx(
                  () => Column(
                    children: [
                      _sectionHeader(
                        "Direct Messages",
                        dmOpen,
                        () => dmOpen = !dmOpen,
                      ),

                      if (dmOpen) ...[
                        for (var driver
                            in _overviewController
                                    .overview
                                    .value
                                    .onlineDrivers ??
                                [])
                          UserStatusTile(
                            name: driver.profiles?[0].username ?? "-",
                            id: driver.profiles?[0].id ?? "-",
                            isOnline: driver.profiles?[0].isOnline ?? false,
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ==================== TRUCK MESSAGES ====================
                Obx(
                  () => Column(
                    children: [
                      _sectionHeader(
                        "Truck Groups",
                        tOpen,
                        () => tOpen = !tOpen,
                      ),

                      if (tOpen) ...[
                        for (var truck
                            in _overviewController
                                    .overview
                                    .value
                                    .trucksgroups ??
                                [])
                          UserStatusTile(
                            name: truck.name ?? "-",
                            id: truck.id ?? "-",
                            isOnline: false,
                            type: TYPE.truck,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Collapsible Section Header
  Widget _sectionHeader(String title, bool open, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: open ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
