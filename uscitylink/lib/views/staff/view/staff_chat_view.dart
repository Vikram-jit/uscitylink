import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/widgets/driver_dialog.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

class StaffChatView extends StatelessWidget {
  StaffChatView({super.key});
  final StaffchannelController _staffchannelController = Get.find<StaffchannelController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService socketService = Get.find<SocketService>();
  // Registered here because the message screen expects it
  // ignore: unused_field
  final StaffchatController _staffchatController = Get.put(StaffchatController());
  final ScrollController _scrollController = ScrollController();

  void _toggleTruckSearch() {
    _staffchannelController.searchController.text = "";
    _staffchannelController.truckSearch.value =
        _staffchannelController.truckSearch.value == "truck" ? "normal" : "truck";
    _staffchannelController.getChnnelChatUser(
        _staffchannelController.currentPage.value + 1, _staffchannelController.searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 2), () {
      socketService.checkVersion();
    });
    _scrollController.addListener(() {
      if (_staffchannelController.loading.value) return;
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (_staffchannelController.currentPage.value < _staffchannelController.totalPages.value) {
          _staffchannelController.getChnnelChatUser(
              _staffchannelController.currentPage.value + 1, _staffchannelController.searchController.text);
        }
      }
    });
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: StaffColors.canvas,
        drawer: CustomDrawer(),
        floatingActionButton: StaffFab(
          heroTag: "chat-1",
          label: "Add driver",
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => DriverDialog.showDriverBottomSheet(context, _staffchannelController),
        ),
        body: Column(
          children: [
            Obx(() {
              final channelName = _staffchannelController.channelChatUser.value.name;
              final truckMode = _staffchannelController.truckSearch.value == "truck";
              return StaffHeader(
                title: "Messages",
                subtitle: channelName == null ? null : "Channel · $channelName",
                onLeading: () => _scaffoldKey.currentState?.openDrawer(),
                bottom: StaffSearchField(
                  controller: _staffchannelController.searchController,
                  onChanged: _staffchannelController.onSearchChanged,
                  hint: truckMode ? "Search by truck number" : "Search by code, name, phone…",
                  suffix: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Tooltip(
                      message: truckMode ? "Searching by truck" : "Search by truck",
                      child: Material(
                        color: truckMode ? StaffColors.primary : StaffColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadii.sm - 4),
                        child: InkWell(
                          onTap: _toggleTruckSearch,
                          borderRadius: BorderRadius.circular(AppRadii.sm - 4),
                          child: SizedBox(
                            width: 34,
                            child: Icon(
                              Icons.local_shipping_rounded,
                              size: 19,
                              color: truckMode ? Colors.white : StaffColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: () async {
                  _staffchannelController.getChnnelChatUser(1, _staffchannelController.searchController.text);
                },
                child: Obx(() {
                  final users = _staffchannelController.channelChatUser.value.userChannels;
                  if (_staffchannelController.loading.value && users == null) {
                    return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
                  }
                  if (users?.isEmpty == true) {
                    return const StaffEmptyState(
                      icon: Icons.forum_outlined,
                      title: "No conversations yet",
                      message: "Drivers in this channel appear here. Use “Add driver” to add one.",
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 96),
                    itemCount: (users?.length ?? 0) + (_staffchannelController.loading.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= (users?.length ?? 0)) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.base),
                          child: Center(child: CircularProgressIndicator(color: StaffColors.primary)),
                        );
                      }
                      final channel = users![index];
                      final profile = channel.userProfile;
                      final driverNumber = profile?.user?.driverNumber;
                      final trucks = channel.assginTrucks ?? "";
                      return StaffListCard(
                        dismissKey: Key('${channel.channelId}-${profile?.id}'),
                        onDismissed: (_) => _staffchannelController.deleteMember(profile!.id!),
                        leading: StaffAvatar(name: profile?.username, online: profile?.isOnline ?? false),
                        title: profile?.username ?? 'Unnamed driver',
                        chips: [
                          if (driverNumber != null && driverNumber.isNotEmpty)
                            StaffPill(label: driverNumber, icon: Icons.badge_outlined, color: StaffColors.textBody),
                          if (trucks.isNotEmpty) StaffPill(label: "Truck $trucks", icon: Icons.local_shipping_rounded),
                        ],
                        subtitle: channel.lastMessage?.body ?? "No messages yet",
                        time: Utils.formatUtcTime(channel.lastMessage?.messageTimestampUtc),
                        unread: channel.unreadCount ?? 0,
                        onTap: () {
                          if (socketService.isConnected.value) {
                            socketService.staffUnreadAllUserMessage(channel.channelId, profile?.id);
                          }
                          Get.toNamed(
                            AppRoutes.staff_user_message,
                            arguments: {
                              'channelId': channel.channelId,
                              'name': profile?.username,
                              'userId': profile?.id
                            },
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
