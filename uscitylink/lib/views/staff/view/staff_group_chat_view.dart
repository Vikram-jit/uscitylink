import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffGroupChatView extends StatefulWidget {
  const StaffGroupChatView({super.key});

  @override
  State<StaffGroupChatView> createState() => _StaffGroupChatViewState();
}

class _StaffGroupChatViewState extends State<StaffGroupChatView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  // Assuming you have a controller to manage unread counts (this will be used in Obx)
  final StaffgroupController _staffGroupController =
      Get.put(StaffgroupController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Initializing the tab controller with 2 tabs (Channels & Groups)
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes if needed
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        // Logic when switching to Channels tab
      }
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        // Logic when switching to Groups tab
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // Add logic for when the app goes to the background
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      // Add logic for when the app comes back to the foreground
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            // Open the drawer using the scaffold key
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: TColors.primaryStaff,
        title: Text("Group Chats",
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white)),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(text: 'Groups'),
            Tab(
              text: 'Truck Groups',
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Channels tab content
          Center(
            child: Text("Channels content goes here"),
          ),
          // Groups tab content
          Center(
            child: Text("Groups content goes here"),
          ),
        ],
      ),
      drawer: CustomDrawer(),
    );
  }
}
