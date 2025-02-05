import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_dashboard.dart';
import 'package:uscitylink/views/driver/views/setting_view.dart';
import 'package:badges/badges.dart' as badges;
import 'package:uscitylink/views/driver/views/training_view.dart';

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
      _currentIndex = index;
    });
    channelController.setTabIndex(index);
    loginController.setTabIndex(index);
  }

  final List<Widget> _screens = [
    const DriverDashboard(),
    const ChatView(),
    DocumentView(),
    TrainingView(),
    const SettingView(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SalomonBottomBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          SalomonBottomBarItem(
              icon: const Icon(Icons.home), title: const Text("Home")),
          SalomonBottomBarItem(
            icon: Obx(() {
              return channelController.totalUnReadMessage.value > 0
                  ? badges.Badge(
                      position: badges.BadgePosition.topEnd(top: -15, end: -9),
                      badgeContent: channelController.totalUnReadMessage.value >
                              0
                          ? Text(
                              '${channelController.totalUnReadMessage.value}',
                              style: TextStyle(color: Colors.white),
                            )
                          : null, // Hide the badge if unread message count is 0
                      child: const Icon(Icons.chat), // Icon for the chat
                    )
                  : const Icon(Icons.chat);
            }),
            title: const Text("Chat"),
          ),
          SalomonBottomBarItem(
              icon: const Icon(Icons.edit_document),
              title: const Text("vehicles")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.class_), title: const Text("Training")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.settings), title: const Text("Settings")),
        ],
      ),
    );
  }
}
