import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/controller/staff/staffview_controller.dart';
import 'package:uscitylink/views/staff/view/staff_channel_view.dart';
import 'package:uscitylink/views/staff/view/staff_chat_view.dart';
import 'package:uscitylink/views/staff/view/staff_dashboard.dart';
import 'package:uscitylink/views/staff/view/staff_group_chat_view.dart';

class StaffView extends StatefulWidget {
  StaffView({
    super.key,
  });

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final StaffviewController _staffviewController =
      Get.put(StaffviewController());

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _staffviewController.setTabIndex(index);
  }

  final List<Widget> _screens = [
    const StaffDashboard(),
    StaffChatView(),
    StaffGroupChatView(),
    StaffChannelView()
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      print("App is in the foreground");
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
              icon: const Icon(Icons.chat), title: const Text("Chat")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.group), title: const Text("Group Chat")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.workspaces),
              title: const Text("Channels")),
        ],
      ),
    );
  }
}
