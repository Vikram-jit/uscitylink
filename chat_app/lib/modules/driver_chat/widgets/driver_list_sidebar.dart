import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/theme/spacing.dart';
import 'package:chat_app/core/theme/text_styles.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/desktop/components/user_status_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DriverListSidebar extends StatelessWidget {
  final bool isTyping;
  final String selectDriverId;
  DriverListSidebar({
    super.key,
    required this.isTyping,
    required this.selectDriverId,
  });

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
        padding: EdgeInsetsGeometry.all(6),
        child: Column(
          children: [
            _header(),
            const Divider(color: Colors.white12, height: 1),

            Expanded(
              child: Obx(() {
                final controller = Get.find<ChannelController>();

                if (controller.isLoadingM.value &&
                    controller.channelMembers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    // Alternative scroll detection
                    if (scrollNotification is ScrollEndNotification) {
                      final metrics = scrollNotification.metrics;
                      if (metrics.pixels >= metrics.maxScrollExtent - 100 &&
                          !controller.isLoadingM.value &&
                          controller.hasMore.value) {
                        controller.getChannelMembers(
                          page: controller.currentPage.value + 1,
                        );
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    //controller: controller.scrollController,
                    itemCount:
                        controller.channelMembers.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.channelMembers.length) {
                        return controller.isLoadingM.value
                            ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SizedBox();
                      }

                      final member = controller.channelMembers[index];

                      return Column(
                        children: [
                          Obx(() {
                            return UserStatusTile(
                              name:
                                  "${member.userProfile?.username} (${member.userProfile?.user?.driverNumber})",
                              id: member.userProfile?.id ?? "-",
                              isOnline: member.userProfile?.isOnline ?? false,
                              isTyping:
                                  isTyping &&
                                      selectDriverId == member.userProfile?.id
                                  ? isTyping
                                  : controller.isUserTyping(
                                      member.userProfile?.id ?? "",
                                    ),
                              unreadCount: member.unreadCount ?? 0,
                              message: member.lastMessage?.body ?? "-",
                              truckNumber: member.assginTrucks ?? "-",
                            );
                          }),

                          Divider(),
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
          Expanded(child: Text("US CITY LINK", style: TStyle.channelTitle)),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
