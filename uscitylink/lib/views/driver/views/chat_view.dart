import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/chats/channels_tab.dart';
import 'package:uscitylink/views/driver/views/chats/message_ui.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ChannelController channelController = Get.put(ChannelController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen for tab changes to refetch channels when the Channels tab is selected
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        channelController.getUserChannels();
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
        // backgroundColor: TColors.primary,
        title: Text("Chats", style: Theme.of(context).textTheme.headlineMedium),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Channels"),
            Tab(text: "Groups"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            ChannelTab(channelController: channelController),
            _buildGroupsTab(),
          ],
        ),
      ),
    );
  }

  // Groups Tab Content
  Widget _buildGroupsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: 10, // Example count
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: EdgeInsets.all(
                0), // Remove default padding for better alignment
            leading: Stack(
              clipBehavior:
                  Clip.none, // To allow the icon to overflow the circle
              children: [
                // Circle Avatar for Channel
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    "G$index", // Placeholder text for avatar, can be replaced with an image
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
                // Online Status (Green Circle) on top of the Avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white,
                          width: 2), // White border for contrast
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Channel Name
                Expanded(
                  child: Text(
                    "Group $index", // Channel name
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow
                        .ellipsis, // Handles overflow if the text is too long
                  ),
                ),
                // Message time (right side of title)
                Row(
                  children: [
                    // Message time
                    Text(
                      "10:30 AM", // Example time, replace with actual message time
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
            subtitle: Text(
              "Description of Group $index",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black54),
            ),
            onTap: () {
              Get.toNamed(AppRoutes.driverMessage);
            },
          );
        },
      ),
    );
  }
}
