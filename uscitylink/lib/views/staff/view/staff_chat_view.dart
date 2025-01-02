import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/widgets/driver_dialog.dart';

class StaffChatView extends StatelessWidget {
  StaffChatView({super.key});
  StaffchannelController _staffchannelController =
      Get.find<StaffchannelController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
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
                  SizedBox(
                      width: 10), // Space between the search bar and button
                  // Button next to the search bar
                  Container(
                    height:
                        40, // Height of the container to match the search bar height
                    child: ElevatedButton(
                      onPressed: () {
                        DriverDialog.showDriverBottomSheet(
                            context, _staffchannelController);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        // Set button color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(5), // Rounded corners
                        ),
                        padding:
                            EdgeInsets.zero, // No padding inside the button
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 16, // Font size
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
            _staffchannelController.getChnnelChatUser();
          },
          child: Obx(() {
            if (_staffchannelController.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            // If no channels are available, show loading indicator
            if (_staffchannelController
                    .channelChatUser.value.userChannels?.isEmpty ==
                true) {
              return const Center(child: Text("No Users Found Yet."));
            } else {
              return ListView.builder(
                itemCount: _staffchannelController
                        .channelChatUser?.value?.userChannels?.length ??
                    0,
                itemBuilder: (context, index) {
                  var channel = _staffchannelController
                      .channelChatUser?.value?.userChannels?[index];

                  return Dismissible(
                    key: Key(
                        '${channel?.channelId}'), // Use the unique channel ID
                    direction: DismissDirection.endToStart, // Swipe to delete
                    onDismissed: (direction) {
                      // Handle item removal and show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Channel ${channel?.userProfile?.username} deleted"),
                        ),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(0),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade400,
                        child: Text(
                          channel?.userProfile?.username?.substring(0, 1) ?? '',
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18),
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Channel name
                          Expanded(
                            child: Text(
                              channel?.userProfile?.username ??
                                  'Unnamed Channel',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                                Utils.formatUtcTime(channel
                                        ?.lastMessage?.messageTimestampUtc) ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                              ),

                              // Badge showing unread message count
                              // channel?.recieve_message_count != 0
                              //     ? Badge(
                              //         label: Text(
                              //           channel.recieve_message_count == 0
                              //               ? ""
                              //               : '${channel.recieve_message_count}', // Example unread count, replace with actual count
                              //           style: const TextStyle(fontSize: 11),
                              //         ),
                              //         backgroundColor: TColors.primary,
                              //       )
                              //     : const SizedBox(),
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
              );
            }
          }),
        ),
      ),
      drawer: CustomDrawer(),
    );
  }
}
