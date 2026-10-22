import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/controller/staff/staffview_controller.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/controller/staff/system_message_controller.dart';
import 'package:uscitylink/views/staff/view/compliance/scale_checks_view.dart';
import 'package:uscitylink/views/staff/view/system_messages/system_messages_view.dart';
import 'package:uscitylink/model/staff/staff_dashboard_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/view/staff_channel_members_view.dart';
import 'package:uscitylink/views/staff/view/staff_templates_view.dart';
import 'package:uscitylink/views/staff/view/staff_trainings_view.dart';
import 'package:uscitylink/views/staff/widgets/driver_dialog.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

// The staff and alert groups live in the company channel (unchanged from the previous dashboard)
const _kCompanyChannelId = "1cb8a91e-921f-40fc-873f-af30d2ee3da0";
const _kStaffGroupId = "b212c6df-1d52-4efd-a012-27d9e2b6a29d";
const _kAlertGroupId = "1fe8cc7c-482f-4cdc-8d22-8ba0bb3b3578";

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with WidgetsBindingObserver {
  final CustomDrawerController _customDrawerController = Get.put(CustomDrawerController());
  final DashboardController _dashboardController = Get.find<DashboardController>();
  final StaffviewController _staffviewController = Get.find<StaffviewController>();
  final StaffchannelController _staffchannelController = Get.find<StaffchannelController>();
  final LoginController _loginController = Get.put(LoginController());
  final ComplianceController _complianceController = Get.put(ComplianceController());
  final SystemMessageController _systemMessageController = Get.put(SystemMessageController());
  final SocketService socketService = Get.find<SocketService>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getStaffDashboard();
    _refreshAttention();
    // Name and role for the header (the drawer used to be the only place that loaded them)
    if (_loginController.userProfile.value.username == null) _loginController.getProfile();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Timer(const Duration(seconds: 2), () {
        socketService.checkVersion();
      });
    }
  }

  /// Scale tickets waiting for release and unread system messages
  Future<void> _refreshAttention() async {
    await Future.wait([_complianceController.refreshPendingCount(), _systemMessageController.loadUnread()]);
  }

  void _openAndRefresh(Widget page) {
    Get.to(() => page)?.then((_) => _refreshAttention());
  }

  Future<void> _refresh() async {
    _refreshAttention();
    _dashboardController.getStaffDashboard();
    // getStaffDashboard() does not return its future; wait until it settles
    while (_dashboardController.loading.value) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _openGroup(String name, String groupId) {
    Get.toNamed(
      AppRoutes.staffGroupMessage,
      arguments: {'channelId': _kCompanyChannelId, 'name': name, 'groupId': groupId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _customDrawerController.scaffoldKey,
      backgroundColor: StaffColors.canvas,
      drawer: CustomDrawer(),
      body: Obx(() {
        final data = _dashboardController.dashboardStaff.value;
        final firstLoad = _dashboardController.loading.value && data.driverCount == null;
        final profile = _loginController.userProfile.value;
        final activeChannel = _staffchannelController.channels.firstWhereOrNull((c) => c.isActive == true);
        return StaffDashboardBody(
          data: data,
          loading: firstLoad,
          name: profile.username,
          role: profile.role?.name,
          channelName: activeChannel?.name,
          connected: socketService.isConnected.value,
          pendingScaleChecks: _complianceController.pendingCount.value,
          unreadSystemMessages: _systemMessageController.unread.length,
          onScaleChecks: () => _openAndRefresh(const ScaleChecksView()),
          onSystemMessages: () => _openAndRefresh(const SystemMessagesView()),
          onRefresh: _refresh,
          onMenu: _customDrawerController.openDrawer,
          onOpenChats: () => _staffviewController.currentIndex.value = 1,
          onDrivers: () => Get.to(() => StaffChannelMembersView()),
          onTemplates: () => Get.to(() => StaffTemplatesView()),
          onTrainings: () => Get.to(() => StaffTrainingsView()),
          onTruckGroups: () => _staffviewController.currentIndex.value = 2,
          onStaffGroup: () => _openGroup("Staff", _kStaffGroupId),
          onAlertGroup: () => _openGroup("Alert", _kAlertGroupId),
          onAddDriver: () => DriverDialog.showDriverBottomSheet(context, _staffchannelController),
          onAllDrivers: () => Get.toNamed(AppRoutes.staff_drivers),
          onChannels: () => _staffviewController.currentIndex.value = 3,
        );
      }),
    );
  }
}

/// The dashboard layout on its own (plain values in, callbacks out), so it can be previewed and
/// tested without controllers or the network.
class StaffDashboardBody extends StatelessWidget {
  final StaffDashboardModel data;
  final bool loading;
  final String? name;
  final String? role;
  final String? channelName;
  final bool connected;
  final int pendingScaleChecks;
  final int unreadSystemMessages;
  final VoidCallback onScaleChecks;
  final VoidCallback onSystemMessages;
  final Future<void> Function() onRefresh;
  final VoidCallback onMenu;
  final VoidCallback onOpenChats;
  final VoidCallback onDrivers;
  final VoidCallback onTemplates;
  final VoidCallback onTrainings;
  final VoidCallback onTruckGroups;
  final VoidCallback onStaffGroup;
  final VoidCallback onAlertGroup;
  final VoidCallback onAddDriver;
  final VoidCallback onAllDrivers;
  final VoidCallback onChannels;
  final DateTime? now;

  const StaffDashboardBody({
    super.key,
    required this.data,
    required this.loading,
    required this.name,
    required this.role,
    required this.channelName,
    required this.connected,
    this.pendingScaleChecks = 0,
    this.unreadSystemMessages = 0,
    required this.onScaleChecks,
    required this.onSystemMessages,
    required this.onRefresh,
    required this.onMenu,
    required this.onOpenChats,
    required this.onDrivers,
    required this.onTemplates,
    required this.onTrainings,
    required this.onTruckGroups,
    required this.onStaffGroup,
    required this.onAlertGroup,
    required this.onAddDriver,
    required this.onAllDrivers,
    required this.onChannels,
    this.now,
  });

  static const double _kHeroOverlap = 56;

  @override
  Widget build(BuildContext context) {
    final unread = data.userUnMessage ?? 0;
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: StaffColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(children: [_header(context), const SizedBox(height: _kHeroOverlap)]),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: 0,
                  child: _UnreadHero(count: unread, loading: loading, onTap: onOpenChats),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StaffSectionTitle(title: 'Needs your attention'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _AttentionTile(
                          icon: Icons.scale_rounded,
                          label: 'Scale checks',
                          caption: pendingScaleChecks == 1 ? 'ticket to release' : 'tickets to release',
                          count: pendingScaleChecks,
                          color: StaffColors.sky,
                          onTap: onScaleChecks,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AttentionTile(
                          icon: Icons.notifications_active_rounded,
                          label: 'System messages',
                          caption: 'unread gate events',
                          count: unreadSystemMessages,
                          color: StaffColors.warning,
                          onTap: onSystemMessages,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const StaffSectionTitle(title: 'Fleet & people', subtitle: 'Your channel at a glance'),
                  const SizedBox(height: AppSpacing.md),
                  _grid([
                    StaffStatTile(
                      icon: Icons.badge_rounded,
                      label: 'Drivers',
                      caption: 'Channel members',
                      value: data.driverCount ?? 0,
                      color: StaffColors.sky,
                      onTap: onDrivers,
                    ),
                    StaffStatTile(
                      icon: Icons.local_shipping_rounded,
                      label: 'Truck groups',
                      caption: 'Group chats',
                      value: data.truckGroupCount ?? 0,
                      color: StaffColors.teal,
                      onTap: onTruckGroups,
                    ),
                    StaffStatTile(
                      icon: Icons.description_rounded,
                      label: 'Templates',
                      caption: 'Quick replies',
                      value: data.templateCount ?? 0,
                      color: StaffColors.violet,
                      onTap: onTemplates,
                    ),
                    StaffStatTile(
                      icon: Icons.play_circle_rounded,
                      label: 'Training videos',
                      caption: 'Assigned to drivers',
                      value: data.trainingCount ?? 0,
                      color: StaffColors.orange,
                      onTap: onTrainings,
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  const StaffSectionTitle(title: 'Team channels', subtitle: 'Internal groups for dispatch'),
                  const SizedBox(height: AppSpacing.md),
                  _TeamChannelRow(
                    icon: Icons.groups_2_rounded,
                    title: 'Staff group',
                    subtitle: 'Dispatch team conversation',
                    count: data.staffGroupCount ?? 0,
                    color: StaffColors.primary,
                    onTap: onStaffGroup,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TeamChannelRow(
                    icon: Icons.campaign_rounded,
                    title: 'Alert group',
                    subtitle: 'Urgent notices & alerts',
                    count: data.alertGroupCount ?? 0,
                    color: StaffColors.danger,
                    onTap: onAlertGroup,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const StaffSectionTitle(title: 'Quick actions'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Add driver', onTap: onAddDriver)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickAction(icon: Icons.contacts_rounded, label: 'All drivers', onTap: onAllDrivers)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _QuickAction(icon: Icons.hub_rounded, label: 'Channels', onTap: onChannels)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> tiles) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: StaffColors.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.header)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset + AppSpacing.sm, AppSpacing.lg, AppSpacing.xl + _kHeroOverlap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StaffGlassButton(icon: Icons.menu_rounded, onTap: onMenu, tooltip: 'Menu'),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
                child: Image.asset(TImages.logo, fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${staffGreeting(now)},',
            style: AppText.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.72)),
          ),
          Text(
            first.isEmpty ? 'Welcome back' : first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.displayLg.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StaffPill(label: staffRoleLabel(role), icon: Icons.verified_user_rounded, onDark: true),
              StaffPill(label: channelName ?? 'U S CITYLINK INC', icon: Icons.hub_rounded, onDark: true),
              _LivePill(connected: connected),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final bool connected;
  const _LivePill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            connected ? 'Live' : 'Reconnecting',
            style: AppText.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _UnreadHero extends StatelessWidget {
  final int count;
  final bool loading;
  final VoidCallback onTap;

  const _UnreadHero({required this.count, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.xl), boxShadow: AppShadows.raised),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppGradients.messages,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.forum_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      loading
                          ? const SizedBox(
                              height: 34,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: StaffColors.primary),
                                ),
                              ),
                            )
                          : Text(
                              '$count',
                              style: AppText.numeric(AppText.displayLg).copyWith(color: StaffColors.textStrong),
                            ),
                      Text(
                        count == 1 ? 'Unread driver message' : 'Unread driver messages',
                        style: AppText.bodySm.copyWith(color: StaffColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: StaffColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open', style: AppText.labelLg.copyWith(color: Colors.white)),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamChannelRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _TeamChannelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.md), boxShadow: AppShadows.card),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySm.copyWith(color: StaffColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (count > 0) ...[
                  StaffCountBadge(count: count, color: color),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Icon(Icons.chevron_right_rounded, color: StaffColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StaffColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base, horizontal: AppSpacing.xs),
          child: Column(
            children: [
              Icon(icon, color: StaffColors.primary, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.labelLg.copyWith(color: StaffColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact tile for work waiting on dispatch; turns quiet (grey count) when there is nothing to do.
class _AttentionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _AttentionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.md), boxShadow: AppShadows.card),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.sm)),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: AppText.numeric(AppText.headline)
                            .copyWith(color: active ? StaffColors.textStrong : StaffColors.textMuted),
                      ),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.labelLg.copyWith(color: StaffColors.textBody)),
                      Text(caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
