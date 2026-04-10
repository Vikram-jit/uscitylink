import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/theme/spacing.dart';
import 'package:chat_app/core/theme/text_styles.dart';
import 'package:chat_app/modules/home/desktop/components/user_status_tile.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/widgets/add_group_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupList extends StatelessWidget {
  GroupList({super.key});

  final GroupController controller = Get.find<GroupController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      decoration: BoxDecoration(
        color: AppColors.channelSideColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _header(),
            const Divider(color: Colors.white12, height: 1),

            /// ✅ ONLY UI REACTIVITY HERE
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.groups.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification) {
                      final metrics = scrollNotification.metrics;
                      if (metrics.pixels >= metrics.maxScrollExtent - 100 &&
                          !controller.isLoading.value &&
                          controller.hasMore.value) {
                        controller.getGroups(
                          page: controller.currentPage.value + 1,
                        );
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    //controller: controller.scrollController,
                    itemCount:
                        controller.groups.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.groups.length) {
                        return controller.isLoading.value
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox();
                      }

                      final group = controller.groups[index];

                      return Column(
                        children: [
                          UserStatusTile(
                            name: group.name ?? "-",
                            id: group.id ?? "-",
                            isOnline: false,
                            unreadCount: group.messageCount ?? 0,
                            message: group.lastMessage?.body ?? "-",
                            type: TYPE.truck,
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text("Truck Groups", style: TStyle.channelTitle)),

          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            onPressed: () {
              Get.dialog(AddGroupDialog(type: "truck"));
            },
          ),
        ],
      ),
    );
  }
}
