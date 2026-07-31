import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/widegts/chat_list_tile.dart';

class ChannelTab extends StatelessWidget {
  // Pass the controller as a parameter to this widget
  final ChannelController channelController;

  SocketService socketServive = Get.find<SocketService>();

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
          if (channelController.loading.value) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF171233)));
          }
          // If no channels are available, show loading indicator
          if (channelController.channels.isEmpty) {
            return const ChatEmptyState(
              icon: Icons.forum_outlined,
              message: "No channels found yet.",
            );
          } else {
            return ListView.builder(
              itemCount: channelController.channels.length,
              itemBuilder: (context, index) {
                var channel = channelController.channels[index];

                return ChatListTile(
                  dismissKey: Key('${channel.id}'),
                  name: channel.channel?.name ?? 'Unnamed Channel',
                  subtitle: channel.last_message?.body,
                  timeLabel: Utils.formatUtcTime(
                      channel.last_message?.messageTimestampUtc),
                  unreadCount: channel.recieve_message_count ?? 0,
                  onDismissed: (direction) {
                    // Handle item removal and show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text("Channel ${channel.channel?.name} deleted"),
                      ),
                    );
                  },
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
                );
              },
            );
          }
        }),
      ),
    );
  }
}
