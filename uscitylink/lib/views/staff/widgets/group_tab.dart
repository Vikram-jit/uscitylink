import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
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
      padding: EdgeInsets.zero,
      child: Obx(() {
        if (_staffgroupController.loading.value &&
            (_staffgroupController.groups.value?.data?.isEmpty ?? true)) {
          return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
        }
        if (_staffgroupController.groups.value?.data?.isEmpty ?? true) {
          return StaffEmptyState(icon: Icons.groups_outlined, title: "No groups found", message: "Pull down to refresh, or create one with the button below.");
        }
        return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 96),
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
              return StaffListCard(
                  dismissKey: Key('${group?.id}'),
                  onDismissed: (direction) {
                    _staffgroupController.deleteGroup(group!.id!);
                  },
                  leading: StaffAvatar(name: group?.name),
                  title: group?.name ?? 'Unnamed group',
                  subtitle: group?.lastMessage?.body ?? "No messages yet",
                  time: Utils.formatUtcTime(group?.lastMessage?.messageTimestampUtc),
                  unread: group?.messageCount ?? 0,
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
                  }
                );
            });
      }),
    );
  }
}
