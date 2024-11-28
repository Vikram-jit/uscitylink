import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';

class GroupTab extends StatelessWidget {
  // Pass the controller as a parameter to this widget
  final GroupController groupController;

  SocketService socketServive = Get.put(SocketService());

  GroupTab({super.key, required this.groupController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: () async {
          // Trigger the refresh action when the user pulls down the list
          groupController.getUserGroups();
        },
        child: Obx(() {
          // If no channels are available, show loading indicator
          if (groupController.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
              itemCount: groupController.groups.length,
              itemBuilder: (context, index) {
                var group = groupController.groups[index];

                return Dismissible(
                  key: Key('${group.id}'), // Use the unique channel ID
                  direction: DismissDirection.endToStart, // Swipe to delete
                  onDismissed: (direction) {
                    // Handle item removal and show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Channel ${group.group?.name} deleted"),
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
                        group.group?.name?.substring(0, 1) ?? '',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Channel name
                        Expanded(
                          child: Text(
                            group.group?.name ?? 'Unnamed Group',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Time and Badge column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Formatted time (UTC converted to local time)
                            // Text(
                            //   Utils.formatUtcTime(channel
                            //           .last_message?.messageTimestampUtc) ??
                            //       '',
                            //   style: const TextStyle(
                            //       fontSize: 12, color: Colors.black45),
                            // ),

                            // Badge showing unread message count
                            // channel.recieve_message_count != 0
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
                      "Not message yet", // Message body or description
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      socketServive.addUserToGroup(
                          group.group!.groupChannel!.channelId!,
                          group.groupId!);

                      Get.toNamed(
                        AppRoutes.driverGroupMessage,
                        arguments: {
                          'channelId': group.group?.groupChannel?.channelId,
                          'name': group.group?.name,
                          'groupId': group.group?.id
                        },
                      );
                    },
                  ),
                );
              },
            );
          }
        }),
      ),
    );
  }
}
