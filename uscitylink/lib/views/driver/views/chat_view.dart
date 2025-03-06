import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/driver/views/chats/channels_tab.dart';
import 'package:uscitylink/views/driver/views/group/groups_tab.dart';
import 'package:badges/badges.dart' as badges;

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  SocketService socketService = Get.find<SocketService>();
  ChannelController channelController = Get.find<ChannelController>();
  GroupController groupController = Get.put(GroupController());
  DashboardController _dashboardController = Get.find<DashboardController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to refetch channels when the Channels tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        channelController.getUserChannels();
      }
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        groupController.getUserGroups();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will run after the widget tree is built, avoiding the error
      channelController.getUserChannels();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // if (channelController.initialized) {
    //   channelController.dispose();
    // }

    // groupController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            _dashboardController.getDashboard();
            Get.back();

            // Open the drawer using the scaffold key
            // _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text("Chats",
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white)),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.white,
          onTap: (index) => channelController.setInnerTabIndex(index),
          controller: _tabController,
          tabs: [
            Obx(() {
              // Check if unread messages are more than 0
              if (channelController.channelCount.value > 0) {
                // Show the badge if unread messages > 0
                return Tab(
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -15, end: -15),
                    badgeContent: Text(
                      '${channelController.channelCount.value}',
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Text('Channels'),
                  ),
                );
              } else {
                // No badge if unread messages are 0
                return const Tab(text: 'Channels');
              }
            }),
            Obx(() {
              // Check if unread messages are more than 0
              if (channelController.groupCount.value > 0) {
                // Show the badge if unread messages > 0
                return Tab(
                  child: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -15, end: -15),
                    badgeContent: Text(
                      '${channelController.groupCount.value}',
                      style: TextStyle(color: Colors.white),
                    ),
                    child: Text('Groups'),
                  ),
                );
              } else {
                // No badge if unread messages are 0
                return const Tab(text: 'Groups');
              }
            }),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChannelTab(channelController: channelController),
          GroupTab(groupController: groupController),
        ],
      ),
      drawer: DriverCustomDrawer(
        globalKey: _scaffoldKey,
      ),
    );
  }
}
