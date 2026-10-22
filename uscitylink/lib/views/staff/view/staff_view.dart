import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/staff/staffview_controller.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/views/staff/view/staff_channel_view.dart';
import 'package:uscitylink/views/staff/view/staff_chat_view.dart';
import 'package:uscitylink/views/staff/view/staff_dashboard.dart';
import 'package:uscitylink/views/staff/view/staff_group_chat_view.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

class StaffView extends StatefulWidget {
  StaffView({
    super.key,
  });

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> with WidgetsBindingObserver {
  final StaffviewController _staffviewController = Get.put(StaffviewController());
  final DashboardController _dashboardController = Get.find<DashboardController>();

  final List<Widget> _screens = [
    StaffDashboard(),
    StaffChatView(),
    StaffGroupChatView(),
    StaffChannelView()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Obx(() {
        return IndexedStack(
          index: _staffviewController.currentIndex.value,
          children: _screens,
        );
      }),
      bottomNavigationBar: Obx(() {
        final unread = _dashboardController.dashboardStaff.value.userUnMessage ?? 0;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: StaffColors.hairline)),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              indicatorColor: StaffColors.primary.withValues(alpha: 0.10),
              height: 68,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => AppText.labelMd.copyWith(
                  fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                  color: states.contains(WidgetState.selected) ? StaffColors.primary : StaffColors.textMuted,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: 24,
                  color: states.contains(WidgetState.selected) ? StaffColors.primary : StaffColors.textMuted,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _staffviewController.currentIndex.value,
              onDestinationSelected: _staffviewController.setTabIndex,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    backgroundColor: StaffColors.danger,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unread > 0,
                    backgroundColor: StaffColors.danger,
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: const Icon(Icons.chat_bubble_rounded),
                  ),
                  label: 'Chats',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Groups',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub_rounded),
                  label: 'Channels',
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
