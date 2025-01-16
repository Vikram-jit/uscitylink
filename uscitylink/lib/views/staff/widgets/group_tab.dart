import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';

class GroupTab extends StatefulWidget {
  const GroupTab({super.key});

  @override
  State<GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<GroupTab> {
  StaffgroupController _staffgroupController = Get.find<StaffgroupController>();
  SocketService _socketService = Get.find<SocketService>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() {
        if (_staffgroupController.loading.value &&
            (_staffgroupController.groups.value?.data?.isEmpty ?? true)) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (_staffgroupController.groups.value?.data?.isEmpty ?? true) {
          return Center(child: Text("No any record found."));
        }
        return ListView.builder(
            controller: ScrollController()
              ..addListener(() {
                if (_staffgroupController.loading.value) return;
                if (_staffgroupController.currentPage.value <
                    _staffgroupController.totalPages.value) {
                  final groupData = _staffgroupController.groups.value.data;
                  if (groupData != null && groupData.isNotEmpty) {
                    final lastItem = groupData[groupData.length - 1];
                    if (lastItem == groupData[groupData.length - 1]) {
                      _staffgroupController.getGroups(
                          _staffgroupController.currentPage.value + 1,
                          _staffgroupController.searchController.text);
                    }
                  }
                }
              }),
            itemCount: _staffgroupController.groups.value.data?.length,
            itemBuilder: (context, index) {
              if (index == _staffgroupController.groups?.value?.data?.length) {
                if (_staffgroupController.currentPage.value <
                    _staffgroupController.totalPages.value) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return SizedBox(); // No more data to load
                }
              }
              var group = _staffgroupController.groups.value.data?[index];
              return Dismissible(
                key: Key('${group?.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _staffgroupController.deleteGroup(group!.id!);
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
                      group?.name?.substring(0, 1) ?? '',
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group?.name ?? 'Unnamed Group',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Utils.formatUtcTime(
                                    group?.lastMessage?.messageTimestampUtc) ??
                                '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45),
                          ),
                          group?.messageCount != 0
                              ? Badge(
                                  label: Text(
                                    group?.messageCount == 0
                                        ? ""
                                        : '${group?.messageCount}',
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
                    group?.lastMessage?.body ?? "Not message yet",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    if (group != null) {
                      _socketService.updateStaffGroup(group.id!);
                    }

                    Get.toNamed(
                      AppRoutes.staffGroupMessage,
                      arguments: {
                        'channelId': group?.groupChannel?.channelId,
                        'name': group?.name,
                        'groupId': group?.id
                      },
                    );
                  },
                ),
              );
            });
      }),
    );
  }
}
