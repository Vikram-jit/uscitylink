import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/views/driver/views/chats/channels_tab.dart';
import 'package:uscitylink/views/driver/views/group/groups_tab.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ChannelController channelController = Get.put(ChannelController());
  GroupController groupController = Get.put(GroupController());

  @override
  void initState() {
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
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
          tabs: const [
            Tab(text: "Channels"),
            Tab(text: "Groups"),
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
    );
  }
}
