import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';

class GroupTab extends StatelessWidget {
  final GroupController groupController;

  SocketService socketServive = Get.put(SocketService());

  GroupTab({super.key, required this.groupController});

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
            return const Center(child: CircularProgressIndicator());
          }
          if (groupController.groups.isEmpty) {
            return const Center(child: Text("No Group Found Yet."));
          } else {
            return ListView.builder(
              itemCount: groupController.groups.length,
              itemBuilder: (context, index) {
                var group = groupController.groups[index];

                return Dismissible(
                  key: Key('${group.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
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
                        Expanded(
                          child: Text(
                            group.group?.name ?? 'Unnamed Group',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              Utils.formatUtcTime(group
                                      .last_message?.messageTimestampUtc) ??
                                  '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                            group.message_count != 0
                                ? Badge(
                                    label: Text(
                                      group.message_count == 0
                                          ? ""
                                          : '${group.message_count}',
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
                      group.last_message?.body ?? "Not message yet",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onTap: () {
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
