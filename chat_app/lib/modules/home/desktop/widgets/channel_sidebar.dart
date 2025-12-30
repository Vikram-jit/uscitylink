import 'package:chat_app/modules/home/desktop/components/channel_tile.dart';
import 'package:chat_app/modules/home/desktop/components/user_status_tile.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: AppColors.channelSideColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Column(
        children: [
          // 🔹 Sidebar Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text("US CITY LINK", style: TStyle.channelTitle),
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
                  ChannelTile("Channels", icon: Icons.ac_unit),
                  ChannelTile("Channel Memmbers", icon: Icons.groups),
                  ChannelTile("Templates", icon: Icons.brush),
                  ChannelTile("Users", icon: Icons.person_off),
                  ChannelTile("Drivers", icon: Icons.drive_eta),
                  ChannelTile("Announcements", icon: Icons.campaign),
                ],

                const SizedBox(height: 10),

                // ==================== DIRECT MESSAGES ====================
                _sectionHeader(
                  "Direct Messages",
                  dmOpen,
                  () => setState(() => dmOpen = !dmOpen),
                ),

                if (dmOpen) ...[
                  UserStatusTile(name: "John Doe", isOnline: true),
                  UserStatusTile(name: "Jane Smith", isOnline: false),
                  UserStatusTile(name: "Michael Adams", isOnline: true),
                ],

                const SizedBox(height: 10),

                // ==================== TRUCK MESSAGES ====================
                _sectionHeader(
                  "Truck Groups",
                  tOpen,
                  () => setState(() => tOpen = !tOpen),
                ),

                if (tOpen) ...[
                  UserStatusTile(name: "22222", isOnline: false),
                  UserStatusTile(name: "12345", isOnline: false),
                  UserStatusTile(name: "12345", isOnline: false),
                ],
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
