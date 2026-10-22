import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffChannelView extends StatefulWidget {
  const StaffChannelView({super.key});

  @override
  State<StaffChannelView> createState() => _StaffChannelViewState();
}

class _StaffChannelViewState extends State<StaffChannelView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final StaffchannelController _channelController =
      Get.find<StaffchannelController>();

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   _channelController.getUserChannels();
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: StaffColors.canvas,
        drawer: CustomDrawer(),
        body: Column(
          children: [
            StaffHeader(
              title: "Channels",
              subtitle: "Pick the channel you are working in",
              onLeading: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: Obx(() {
                final channels = _channelController.channels;
                if (channels.isEmpty) {
                  return const StaffEmptyState(
                    icon: Icons.hub_outlined,
                    title: "No channels",
                    message: "Channels you are a member of appear here.",
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: channels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final active = channel.isActive == true;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: AppShadows.card,
                        border: Border.all(
                          color: active ? StaffColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () => _channelController.updateActiveChannel(channel.id!),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                StaffAvatar(name: channel.name, icon: Icons.hub_rounded, size: 44),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${channel.name}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.titleMd.copyWith(color: StaffColors.textStrong),
                                      ),
                                      Text(
                                        active ? 'Current channel' : 'Tap to switch',
                                        style: AppText.bodySm.copyWith(
                                          color: active ? StaffColors.success : StaffColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: active ? StaffColors.primary : StaffColors.textMuted.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
