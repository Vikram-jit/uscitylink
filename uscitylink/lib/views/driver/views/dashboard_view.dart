import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/training_controller.dart';

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
    // const ChatView(),
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
    return Scaffold(body: Obx(() {
      return IndexedStack(
        index: channelController.currentIndex.value,
        children: _screens,
      );
    }), bottomNavigationBar: Obx(() {
      return SalomonBottomBar(
        backgroundColor: Colors.white,
        currentIndex: channelController.currentIndex.value,
        onTap: _onItemTapped,
        items: [
          SalomonBottomBarItem(
              icon: const Icon(Icons.home), title: const Text("Home")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.settings), title: const Text("Settings")),
        ],
      );
    }));
  }
}
