import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_dashboard.dart';
import 'package:uscitylink/views/driver/views/setting_view.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => SalomonBottomBar(
          currentIndex: controller.selectedIndex.value,
          onTap: (index) => controller.selectedIndex.value = index,
          items: [
            SalomonBottomBarItem(
                icon: const Icon(Icons.home), title: const Text("Home")),
            SalomonBottomBarItem(
                icon: const Icon(Icons.chat), title: const Text("Chat")),
            SalomonBottomBarItem(
                icon: const Icon(Icons.edit_document),
                title: const Text("Documents")),
            SalomonBottomBarItem(
                icon: const Icon(Icons.settings),
                title: const Text("Settings")),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const DriverDashboard(),
    const ChatView(),
    DocumentView(),
    SettingView(),
  ];
}
