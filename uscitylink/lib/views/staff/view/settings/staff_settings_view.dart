import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/staff/notification_settings_controller.dart';
import 'package:uscitylink/services/staff/notification_settings_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Staff → Settings: mute message notifications and call alerts (separately) for a while, plus
/// account and app details.
class StaffSettingsView extends StatefulWidget {
  const StaffSettingsView({super.key});

  @override
  State<StaffSettingsView> createState() => _StaffSettingsViewState();
}

class _MuteOption {
  final String label;
  final int? minutes;
  final bool forever;
  const _MuteOption(this.label, {this.minutes, this.forever = false});
}

const _muteOptions = [
  _MuteOption('For 1 hour', minutes: 60),
  _MuteOption('For 8 hours', minutes: 8 * 60),
  _MuteOption('For 24 hours', minutes: 24 * 60),
  _MuteOption('Until I turn them back on', forever: true),
];

class _StaffSettingsViewState extends State<StaffSettingsView> {
  final NotificationSettingsController _controller = Get.put(NotificationSettingsController());
  // Already registered by the drawer that opens this screen
  final LoginController? _login = Get.isRegistered<LoginController>() ? Get.find<LoginController>() : null;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _controller.load();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  Future<void> _chooseMute(MuteKind kind) async {
    final option = await showModalBottomSheet<_MuteOption>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Text(kind == MuteKind.calls ? 'Mute call alerts' : 'Mute notifications',
                  style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
            ),
            for (final o in _muteOptions)
              ListTile(
                leading: Icon(o.forever ? Icons.notifications_off_rounded : Icons.schedule_rounded, color: StaffColors.primary),
                title: Text(o.label, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                onTap: () => Navigator.pop(ctx, o),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (option != null) await _controller.muteFor(kind: kind, minutes: option.minutes, forever: option.forever);
  }

  String _mutedLabel(NotificationMute m) {
    if (m.forever || m.until == null) return 'Muted until you turn them back on';
    final until = m.until!;
    final now = DateTime.now();
    final sameDay = until.year == now.year && until.month == now.month && until.day == now.day;
    return 'Muted until ${sameDay ? DateFormat('h:mm a').format(until) : DateFormat('EEE, MMM d · h:mm a').format(until)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        body: Column(
          children: [
            StaffHeader(
              title: 'Settings',
              subtitle: 'Notifications and account',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: _controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  children: [
                    _muteCard(MuteKind.messages),
                    _muteCard(MuteKind.calls),
                    _accountCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _muteCard(MuteKind kind) {
    final calls = kind == MuteKind.calls;
    return Obx(() {
      final state = calls ? _controller.callMute.value : _controller.mute.value;
      final muted = state.active;
      final busy = _controller.savingKind.value == kind || (_controller.loading.value && !muted);
      return StaffSectionCard(
        title: calls ? 'Call alerts' : 'Message notifications',
        icon: calls
            ? (muted ? Icons.phone_disabled_rounded : Icons.phone_in_talk_rounded)
            : (muted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded),
        trailing: StaffPill(
          label: muted ? 'Muted' : 'On',
          color: muted ? StaffColors.warning : StaffColors.success,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(calls ? 'Mute call alerts' : 'Mute notifications', style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                      const SizedBox(height: 2),
                      Text(
                        muted
                            ? _mutedLabel(state)
                            : calls
                                ? 'Incoming calls ring this phone'
                                : 'Driver and group messages alert this phone',
                        style: AppText.bodySm.copyWith(color: muted ? StaffColors.warning : StaffColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: StaffColors.primary)),
                  )
                else
                  Switch.adaptive(
                    key: Key(calls ? 'callMuteSwitch' : 'muteSwitch'),
                    value: muted,
                    activeTrackColor: StaffColors.primary,
                    onChanged: (on) => on ? _chooseMute(kind) : _controller.unmute(kind: kind),
                  ),
              ],
            ),
            if (muted) ...[
              const SizedBox(height: AppSpacing.sm),
              // Wraps onto two lines on narrow phones / large text instead of overflowing
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: () => _chooseMute(kind),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(foregroundColor: StaffColors.primary, padding: EdgeInsets.zero),
                  ),
                  FilledButton.icon(
                    key: Key(calls ? 'callUnmute' : 'unmute'),
                    onPressed: () => _controller.unmute(kind: kind),
                    icon: const Icon(Icons.notifications_active_rounded, size: 18),
                    label: const Text('Turn on now'),
                    style: FilledButton.styleFrom(backgroundColor: StaffColors.primary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: StaffColors.sky.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                calls
                    ? 'While muted, calls from drivers and dispatch don\'t ring this phone and go to other dispatchers. If your web dashboard is open, calls still ring there. Message notifications aren\'t affected.'
                    : 'While muted, messages still arrive in the app and unread counts keep updating — only the phone alerts stop. Calls still ring (see Call alerts). This applies to this account on every device.',
                style: AppText.bodySm.copyWith(color: StaffColors.textBody),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _accountCard() {
    Widget card(List<Widget> rows) => StaffSectionCard(
          title: 'Account',
          icon: Icons.person_rounded,
          child: Column(children: [...rows, _row('App version', _appVersion.isEmpty ? '—' : _appVersion)]),
        );
    final login = _login;
    if (login == null) return card(const []);
    return Obx(() {
      final profile = login.userProfile.value;
      return card([
        _row('Name', profile.username ?? '—'),
        _row('Email', profile.user?.email ?? '—'),
        _row('Role', staffRoleLabel(profile.role?.name)),
      ]);
    });
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: AppText.bodySm.copyWith(color: StaffColors.textMuted))),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMd.copyWith(color: StaffColors.textStrong),
              ),
            ),
          ],
        ),
      );
}
