import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/driver_dashboard.dart';
import 'package:uscitylink/views/driver/views/setting_view.dart';

class DashboardView extends StatefulWidget {
  int? currentStep = 0;
  int? chatTabIndex = 0;
  DashboardView({super.key, this.currentStep = 0, this.chatTabIndex = 0});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  final ChannelController channelController = Get.put(ChannelController());
  final LoginController loginController = Get.put(LoginController());

  TrainingController _trainingController = Get.put(TrainingController());
  void _onItemTapped(int index) {
    setState(() {
      channelController.currentIndex.value = index;
    });

    if (index == 3) {
      _trainingController.fetchTrainingVideos(page: 1);
    }
    channelController.setTabIndex(index);
    loginController.setTabIndex(index);
  }

  final List<Widget> _screens = [
    const DriverDashboard(),
    const ChatView(),
    SettingView(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentStep! > 0) {
      setState(() {
        _currentIndex = widget.currentStep!;
      });
    }
    // Populate the unread-message badge on cold start — otherwise it only
    // updates after a tab switch or an incoming push notification.
    channelController.getCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // App is in the background

      print("App is in the background");
      // socketService.disconnect(); // Disconnect the socket when the app goes to background
    } else if (state == AppLifecycleState.resumed) {
      // App is in the foreground

      print("App is in the foreground");
      // socketService
      //     .connectSocket(); // Reconnect the socket when the app comes back to foreground
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return IndexedStack(
          index: channelController.currentIndex.value,
          children: _screens,
        );
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Obx(() {
            return SalomonBottomBar(
              currentIndex: channelController.currentIndex.value,
              onTap: _onItemTapped,
              selectedItemColor: TColors.navyHeaderDeep,
              unselectedItemColor: Colors.grey.shade400,
              itemPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  title: const Text("Home"),
                ),
                SalomonBottomBarItem(
                  icon: _messagesIcon(Icons.chat_bubble_outline_rounded),
                  activeIcon: _messagesIcon(Icons.chat_bubble_rounded),
                  title: const Text("Messages"),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings_rounded),
                  title: const Text("Settings"),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _messagesIcon(IconData icon) {
    final count = channelController.totalUnReadMessage.value;
    if (count <= 0) return Icon(icon);
    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -8, end: -10),
      badgeContent: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Color(0xFFEF4444),
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      child: Icon(icon),
    );
  }
}
