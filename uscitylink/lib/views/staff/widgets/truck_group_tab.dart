import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/utils.dart';

class TruckGroupTab extends StatefulWidget {
  const TruckGroupTab({super.key});

  @override
  State<TruckGroupTab> createState() => _TruckGroupTabState();
}

class _TruckGroupTabState extends State<TruckGroupTab> {
  StaffgroupController _staffgroupController = Get.find<StaffgroupController>();
  SocketService _socketService = Get.find<SocketService>();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() {
        if (_staffgroupController.loading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return ListView.builder(
            itemCount: _staffgroupController.groups.value.data?.length,
            itemBuilder: (context, index) {
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
                        ],
                      ),
                    ],
                  ),
                  subtitle: Text(
                    group?.lastMessage?.body ?? "messages",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () {
                    _socketService?.socket
                        ?.emit('staff_open_truck_group', group?.id);
                    Get.toNamed(
                      AppRoutes.staff_truck_group_detail,
                      arguments: {'groupId': group?.id},
                    );
                  },
                ),
              );
            });
      }),
    );
  }
}
