import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';

class ChannelTab extends StatelessWidget {
  // Pass the controller as a parameter to this widget
  final ChannelController channelController;

  SocketService socketServive = Get.put(SocketService());

  ChannelTab({required this.channelController});

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
            return Center(child: CircularProgressIndicator());
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
                        Expanded(
                          child: Text(
                            channel.channel?.name ?? 'Unnamed Channel',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              "10:30 AM", // Example time, replace with actual message time
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Text(
                      channel.channel?.description ??
                          "No description", // Use channel description
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
                      socketServive.updateActiveChannel(channel.channel!.id!);
                      Get.toNamed(
                        AppRoutes.driverMessage,
                        arguments: {
                          'channelId': channel?.channel?.id,
                          'name': channel?.channel?.name
                        },
                      );
                      // Handle navigation to message screen (pass channel as argument)
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
