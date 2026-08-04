import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_dashboard.dart';
import 'package:uscitylink/views/driver/views/loads_view.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      channelController.currentIndex.value = index;
    });

    channelController.setTabIndex(index);
    loginController.setTabIndex(index);
  }

  final List<Widget> _screens = [
    const DriverDashboard(),
    ChatView(),
    const LoadsView(),
    DocumentView(),
    SettingView(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.currentStep! > 0) {
      setState(() {
        _currentIndex = widget.currentStep!;
      });
    }
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
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  title: const Text("Home"),
                ),
                SalomonBottomBarItem(
                  icon: _messagesIcon(false),
                  activeIcon: _messagesIcon(true),
                  title: const Text("Messages"),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.local_shipping_outlined),
                  activeIcon: const Icon(Icons.local_shipping_rounded),
                  title: const Text("Loads"),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.folder_outlined),
                  activeIcon: const Icon(Icons.folder_rounded),
                  title: const Text("Documents"),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.more_horiz_rounded),
                  activeIcon: const Icon(Icons.more_horiz_rounded),
                  title: const Text("More"),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _messagesIcon(bool active) {
    return Obx(() {
      final unread = channelController.totalUnReadMessage.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(active ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
          if (unread > 0)
            Positioned(
              top: -4,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 15),
                decoration: BoxDecoration(
                  color: TColors.brandRed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
