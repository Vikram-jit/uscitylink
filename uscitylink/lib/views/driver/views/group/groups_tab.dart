import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/widegts/chat_list_tile.dart';

class GroupTab extends StatelessWidget {
  final GroupController groupController;
  final bool selectionMode;
  final ChatTargetSelected? onTargetSelected;

  SocketService socketServive = Get.find<SocketService>();

  GroupTab({
    super.key,
    required this.groupController,
    this.selectionMode = false,
    this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: () async {
          groupController.getUserGroups();
        },
        child: Obx(() {
          if (groupController.loading.value) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF171233)));
          }
          if (groupController.groups.isEmpty) {
            return const ChatEmptyState(
              icon: Icons.groups_outlined,
              message: "No groups found yet.",
            );
          } else {
            return ListView.builder(
              itemCount: groupController.groups.length,
              itemBuilder: (context, index) {
                var group = groupController.groups[index];

                return ChatListTile(
                  dismissKey: Key('${group.id}'),
                  name: group.group?.name ?? 'Unnamed Group',
                  subtitle: group.last_message?.body,
                  timeLabel: Utils.formatUtcTime(
                      group.last_message?.messageTimestampUtc),
                  unreadCount: group.message_count ?? 0,
                  onDismissed: (direction) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Channel ${group.group?.name} deleted"),
                      ),
                    );
                  },
                  onTap: () {
                    if (selectionMode) {
                      onTargetSelected?.call(
                          group.group!.groupChannel!.channelId!,
                          group.groupId,
                          group.group?.name ?? 'Unnamed Group');
                      return;
                    }
                    socketServive.addUserToGroup(
                        group.group!.groupChannel!.channelId!,
                        group.groupId!);
                    socketServive.updateCountGroup(group.groupId!);
                    Get.toNamed(
                      AppRoutes.driverGroupMessage,
                      arguments: {
                        'channelId': group.group?.groupChannel?.channelId,
                        'name': group.group?.name,
                        'groupId': group.group?.id
                      },
                    );
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
