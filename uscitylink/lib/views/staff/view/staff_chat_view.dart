import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/widgets/driver_dialog.dart';

class StaffChatView extends StatelessWidget {
  StaffChatView({super.key});
  StaffchannelController _staffchannelController =
      Get.find<StaffchannelController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SocketService socketService = Get.find<SocketService>();
  StaffchatController _staffchatController = Get.put(StaffchatController());
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    Timer(Duration(seconds: 2), () {
      socketService.checkVersion();
    });
    _scrollController.addListener(() {
      if (_staffchannelController.loading.value) return;
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (_staffchannelController.currentPage.value <
            _staffchannelController.totalPages.value) {
          _staffchannelController.getChnnelChatUser(
              _staffchannelController.currentPage.value + 1,
              _staffchannelController.searchController.text);
        }
      }
    });
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Set height for the AppBar
        child: Column(
          children: [
            AppBar(
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
              backgroundColor: TColors
                  .primaryStaff, // Set your custom color (TColors.primaryStaff)
              title: Obx(() {
                return Text(
                  "Channel ${_staffchannelController.channelChatUser.value.name} Message",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                );
              }),
            ),
            Container(
              height: 60.0, // Height for the search bar + button
              color: TColors
                  .primaryStaff, // Set your custom color (TColors.primaryStaff)
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      height: 40,
                      child: TextField(
                        onChanged: (value) {
                          _staffchannelController.onSearchChanged(value);
                        },
                        controller: _staffchannelController.searchController,
                        decoration: InputDecoration(
                          hintText: "Search user...",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.all(0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger the refresh action when the user pulls down the list
            _staffchannelController.getChnnelChatUser(
                1, _staffchannelController.searchController.text);
          },
          child: Obx(() {
            if (_staffchannelController.loading.value &&
                _staffchannelController.channelChatUser.value.userChannels ==
                    null) {
              return const Center(child: CircularProgressIndicator());
            }
            // If no channels are available, show loading indicator
            if (_staffchannelController
                    .channelChatUser.value.userChannels?.isEmpty ==
                true) {
              return const Center(child: Text("No Users Found Yet."));
            } else {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _staffchannelController
                              .channelChatUser.value.userChannels?.length ??
                          0,
                      itemBuilder: (context, index) {
                        var channel = _staffchannelController
                            .channelChatUser.value.userChannels?[index];

                        return Dismissible(
                          key: Key(
                              '${channel?.channelId}'), // Use the unique channel ID
                          direction:
                              DismissDirection.endToStart, // Swipe to delete

                          onDismissed: (direction) {
                            _staffchannelController
                                .deleteMember(channel!.userProfile!.id!);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            leading: GetBuilder<StaffchannelController>(
                              builder: (controller) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey.shade400,
                                      child: Text(
                                        channel?.userProfile?.username
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '', // Show first letter of username
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),

                                    // Online Badge in the top-right corner, wrapped in Obx
                                    if (channel?.userProfile?.isOnline ??
                                        false) // Show badge if user is online
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .green, // Green color for online status
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors
                                                  .white, // White border around the badge
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Channel name
                                Expanded(
                                  child: Text(
                                    channel?.userProfile?.username ??
                                        'Unnamed Channel',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Time and Badge column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Formatted time (UTC converted to local time)
                                    Text(
                                      Utils.formatUtcTime(channel?.lastMessage
                                              ?.messageTimestampUtc) ??
                                          '',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black45),
                                    ),

                                    // Badge showing unread message count
                                    channel?.unreadCount != 0
                                        ? Badge(
                                            label: Text(
                                              channel?.unreadCount == 0
                                                  ? ""
                                                  : '${channel?.unreadCount}', // Example unread count, replace with actual count
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor: TColors.primary,
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                              ],
                            ),
                            subtitle: Text(
                              channel?.lastMessage?.body ??
                                  "Not message yet", // Message body or description
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            onTap: () {
                              if (socketService.isConnected.value) {
                                socketService.staffUnreadAllUserMessage(
                                    channel?.channelId,
                                    channel?.userProfile?.id);
                              }
                              Get.toNamed(
                                AppRoutes.staff_user_message,
                                arguments: {
                                  'channelId': channel?.channelId,
                                  'name': channel?.userProfile?.username,
                                  'userId': channel?.userProfile?.id
                                },
                              );
                              // Handle navigation to the message screen (pass channel as an argument)
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (_staffchannelController.loading.value)
                    Column(
                      children: [
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    ),
                ],
              );
            }
          }),
        ),
      ),
      drawer: CustomDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "chat-1",
        backgroundColor: Colors.amber,
        onPressed: () {
          DriverDialog.showDriverBottomSheet(context, _staffchannelController);
        },
        label: Text(
          "Add Driver",
          style: TextStyle(color: Colors.white),
        ),
        icon: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
