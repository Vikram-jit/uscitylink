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
  // ✅ Plain bools — always toggled via setState, never inside Obx
  bool channelsOpen = true;
  bool dmOpen = true;
  bool tOpen = true;

  // ✅ Lazy getters — never captured at field level to avoid stale refs
  OverviewController get _overview => Get.find<OverviewController>();
  HomeController get _home => Get.find<HomeController>();

  void _toggle(bool current, void Function(bool) setter) {
    setState(() => setter(!current));
  }

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
          // ── Header ──
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
                      onTap: () {
                        _home.currentView.value = SidebarViewType.home;
                        _home.selectedName.value = '';
                      },
                      child: Text('US CITY LINK', style: TStyle.channelTitle),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // ── Scrollable body ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              children: [
                // ── Channels section ──
                _SectionHeader(
                  title: 'Channels',
                  open: channelsOpen,
                  onTap: () => _toggle(channelsOpen, (v) => channelsOpen = v),
                ),

                if (channelsOpen) ...[
                  ChannelTile(
                    'Channels',
                    icon: Icons.ac_unit,
                    sidebarViewType: SidebarViewType.channel,
                  ),
                  ChannelTile(
                    'Channel Members',
                    icon: Icons.groups,
                    sidebarViewType: SidebarViewType.channelMembers,
                  ),
                  ChannelTile(
                    'Templates',
                    icon: Icons.brush,
                    sidebarViewType: SidebarViewType.template,
                  ),
                  ChannelTile(
                    'Drivers',
                    icon: Icons.drive_eta,
                    sidebarViewType: SidebarViewType.driver,
                  ),
                  ChannelTile(
                    'Users',
                    icon: Icons.person,
                    sidebarViewType: SidebarViewType.users,
                  ),
                ],

                const SizedBox(height: 10),

                // ── Direct Messages section ──
                // ✅ Only the list data is inside Obx — toggle state stays outside
                _SectionHeader(
                  title: 'Direct Messages',
                  open: dmOpen,
                  onTap: () => _toggle(dmOpen, (v) => dmOpen = v),
                ),

                if (dmOpen)
                  Obx(() {
                    final drivers =
                        _overview.overview.value.onlineDrivers ?? [];
                    return Column(
                      children: drivers.map((driver) {
                        final profile = driver.profiles?.isNotEmpty == true
                            ? driver.profiles![0]
                            : null;
                        return UserStatusTile(
                          name: profile?.username ?? '—',
                          id: profile?.id ?? '—',
                          isOnline: profile?.isOnline ?? false,
                          isTyping: _overview.isUserTyping(profile?.id ?? ''),
                          unreadCount: driver.unreadCount ?? 0,
                        );
                      }).toList(),
                    );
                  }),

                const SizedBox(height: 10),

                // ── Truck Groups section ──
                _SectionHeader(
                  title: 'Truck Groups',
                  open: tOpen,
                  onTap: () => _toggle(tOpen, (v) => tOpen = v),
                ),

                if (tOpen)
                  Obx(() {
                    final trucks = _overview.overview.value.trucksgroups ?? [];
                    return Column(
                      children: trucks.map((truck) {
                        return UserStatusTile(
                          name: truck.name ?? '—',
                          id: truck.id ?? '—',
                          isOnline: false,
                          type: TYPE.truck,
                        );
                      }).toList(),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header — extracted as const-friendly widget
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool open;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
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
