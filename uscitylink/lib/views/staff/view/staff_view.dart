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

  void _onItemTapped(int index) {
    if (index == 3) {
      _openFullScreenModal(context);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _openFullScreenModal(BuildContext context) {
    Get.bottomSheet(
      // Full-Screen Draggable Sheet
      DraggableScrollableSheet(
        initialChildSize: 1.0, // Initial size (50% of screen height)
        minChildSize: 1.0, // Minimum size (50% of screen height)
        maxChildSize: 1.0, // Maximum size (90% of screen height)
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                _buildHeader(),
                _buildActions(),
              ],
            ),
          );
        },
      ),
      isDismissible: true, // Dismiss on tap outside
      enableDrag: true, // Enable drag gesture
    );
  }

  // Top drag icon

  // Bottom drag icon
  Widget _buildBottomDragIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Icon(
          Icons.drag_handle,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Header of the sheet
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          SizedBox(height: 20),
          Text(
            'Choose an Action',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  // Actions inside the sheet
  Widget _buildActions() {
    return Column(
      children: [
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Action 1 selected");
          },
          leading: Icon(Icons.access_alarm),
          title: Text('Action 1'),
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Action 2 selected");
          },
          leading: Icon(Icons.account_box),
          title: Text('Action 2'),
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Action 3 selected");
          },
          leading: Icon(Icons.settings),
          title: Text('Action 3'),
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
        Divider(),
        ListTile(
          onTap: () {
            Get.back(); // Close the sheet
            print("Cancel selected");
          },
          leading: Icon(Icons.close),
          title: Text('Cancel'),
          textColor: Colors.red,
        ),
      ],
    );
  }

  final List<Widget> _screens = [
    const StaffDashboard(),
    StaffChatView(),
    StaffGroupChatView()
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
              icon: const Icon(Icons.chat), title: const Text("Chat")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.group), title: const Text("Group Chat")),
          SalomonBottomBarItem(
              icon: const Icon(Icons.workspaces),
              title: const Text("Switch Channels")),
        ],
      ),
    );
  }
}

class ModalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'This is a modal screen',
          style: TextStyle(fontSize: 22),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Get.back(); // Close the modal using GetX
          },
          child: Text('Close Modal'),
        ),
      ],
    );
  }
}
