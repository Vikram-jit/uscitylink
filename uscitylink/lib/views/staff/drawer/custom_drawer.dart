import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
import 'package:uscitylink/views/staff/view/staff_trainings_view.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/controller/staff/system_message_controller.dart';
import 'package:uscitylink/views/staff/view/compliance/equipment_view.dart';
import 'package:uscitylink/views/staff/view/compliance/scale_checks_view.dart';
import 'package:uscitylink/views/staff/view/compliance/weight_rules_view.dart';
import 'package:uscitylink/views/staff/view/system_messages/system_messages_view.dart';

class CustomDrawer extends StatefulWidget {
  CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with WidgetsBindingObserver {
  final loginController = Get.put(LoginController());
  final customDrawerController = Get.find<CustomDrawerController>();
  final complianceController = Get.put(ComplianceController());
  final systemMessageController = Get.put(SystemMessageController());

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // TODO: implement initState
    super.initState();
    loginController.getProfile();
    // Badges for the Compliance and System messages entries
    complianceController.refreshPendingCount();
    systemMessageController.loadUnread();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadii.lg)),
      ),
      child: Column(
        children: [
          Obx(() {
            final profile = loginController.userProfile.value;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset + AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: StaffColors.header,
                borderRadius: BorderRadius.only(topRight: Radius.circular(AppRadii.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Text(
                      StaffAvatar.initials(profile.username),
                      style: AppText.headline.copyWith(color: StaffColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.username ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleLg.copyWith(color: Colors.white),
                  ),
                  if ((profile.user?.email ?? '').isNotEmpty)
                    Text(
                      profile.user!.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  StaffPill(
                    label: staffRoleLabel(profile.role?.name),
                    icon: Icons.verified_user_rounded,
                    onDark: true,
                  ),
                ],
              ),
            );
          }),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.base),
              children: [
                _sectionLabel('Manage'),
                _buildDrawerItem(context, Icons.groups_2_rounded, 'Channel members',
                    () => _navigateToHome(context, customDrawerController)),
                _buildDrawerItem(context, Icons.badge_rounded, 'Drivers', () => _navigateToDrivers(context)),
                _buildDrawerItem(context, Icons.description_rounded, 'Templates', () => _navigateToTemplates(context)),
                _buildDrawerItem(context, Icons.play_circle_rounded, 'Trainings', () => _navigateToTainings(context)),
                Obx(() => _buildDrawerItem(
                      context,
                      Icons.notifications_active_rounded,
                      'System messages',
                      () => _open(const SystemMessagesView()),
                      badge: systemMessageController.unread.length,
                    )),
                const SizedBox(height: AppSpacing.sm),
                _sectionLabel('Compliance'),
                Obx(() => _buildDrawerItem(
                      context,
                      Icons.scale_rounded,
                      'Scale checks',
                      () => _open(const ScaleChecksView()),
                      badge: complianceController.pendingCount.value,
                    )),
                _buildDrawerItem(context, Icons.rv_hookup_rounded, 'Equipment', () => _open(const EquipmentView())),
                _buildDrawerItem(context, Icons.gavel_rounded, 'Weight rules', () => _open(const WeightRulesView())),
                const SizedBox(height: AppSpacing.sm),
                _sectionLabel('App'),
                _buildDrawerItem(context, Icons.settings_rounded, 'Settings', () => {}),
              ],
            ),
          ),
          const Divider(height: 1, color: StaffColors.hairline),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm + MediaQuery.of(context).padding.bottom,
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
              leading: const Icon(Icons.logout_rounded, color: StaffColors.danger),
              title: Text('Log out', style: AppText.titleMd.copyWith(color: StaffColors.danger)),
              onTap: () {
                loginController.logOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
        child: Text(
          text.toUpperCase(),
          style: AppText.labelSm.copyWith(color: StaffColors.textMuted),
        ),
      );

  // Reusable method to build Drawer items
  void _open(Widget page) {
    // The drawer belongs to whichever tab opened it; close it there (the shared key is the dashboard's)
    Scaffold.maybeOf(context)?.closeDrawer();
    customDrawerController.closeDrawer();
    Get.to(() => page)?.then((_) {
      complianceController.refreshPendingCount();
      systemMessageController.loadUnread();
    });
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Function() onTap, {int badge = 0}) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: StaffColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.sm - 2),
        ),
        child: Icon(icon, color: StaffColors.primary, size: 20),
      ),
      title: Text(title, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
      trailing: badge > 0
          ? StaffCountBadge(count: badge, color: StaffColors.danger)
          : const Icon(Icons.chevron_right_rounded, color: StaffColors.textMuted),
      onTap: onTap,
    );
  }

  // Navigation methods
  void _navigateToHome(
      BuildContext context, CustomDrawerController customDrawerController) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_channel_member);
    // Add navigation to Home screen
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    // Add navigation to Profile screen
  }

  void _navigateToDrivers(BuildContext context) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_drivers);
    // Add navigation to Settings screen
  }

  void _navigateToTemplates(BuildContext context) {
    customDrawerController.closeDrawer();
    Get.toNamed(AppRoutes.staff_templates);
    // Add navigation to Settings screen
  }

  void _navigateToTainings(BuildContext context) {
    customDrawerController.closeDrawer();
    Get.to(() => StaffTrainingsView());
    // Add navigation to Settings screen
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.pop(context);
    // Add navigation to Help screen
  }

  void _logout(BuildContext context) {
    loginController.logOut();
    // Handle logout logic
  }
}
