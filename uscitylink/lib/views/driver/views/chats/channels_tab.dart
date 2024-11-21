import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';

class ChannelTab extends StatelessWidget {
  // Pass the controller as a parameter to this widget
  final ChannelController channelController;

  SocketService socketServive = Get.put(SocketService());

  ChannelTab({super.key, required this.channelController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: () async {
          // Trigger the refresh action when the user pulls down the list
          channelController.getUserChannels();
        },
        child: Obx(() {
          // If no channels are available, show loading indicator
          if (channelController.channels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
              itemCount: channelController.channels.length,
              itemBuilder: (context, index) {
                var channel = channelController.channels[index];

                return Dismissible(
                  key: Key('${channel.id}'), // Use the unique channel ID
                  direction: DismissDirection.endToStart, // Swipe to delete
                  onDismissed: (direction) {
                    // Handle item removal and show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Channel ${channel.channel?.name} deleted"),
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
                        channel.channel?.name?.substring(0, 1) ?? '',
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
                            channel.channel?.name ?? 'Unnamed Channel',
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
                            Text(
                              Utils.formatUtcTime(channel
                                      .last_message?.messageTimestampUtc) ??
                                  '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),

                            // Badge showing unread message count
                            channel.recieve_message_count != 0
                                ? Badge(
                                    label: Text(
                                      channel.recieve_message_count == 0
                                          ? ""
                                          : '${channel.recieve_message_count}', // Example unread count, replace with actual count
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: TColors.primary,
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Text(
                      channel.last_message?.body ??
                          "Not message yet", // Message body or description
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      socketServive.updateActiveChannel(channel.channel!.id!);

                      Get.toNamed(
                        AppRoutes.driverMessage,
                        arguments: {
                          'channelId': channel.channel?.id,
                          'name': channel.channel?.name
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
    );
  }
}
