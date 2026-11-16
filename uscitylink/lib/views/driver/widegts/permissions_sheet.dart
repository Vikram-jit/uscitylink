import 'package:flutter/material.dart';
import 'package:uscitylink/services/permissions/app_permissions.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// "Allow what the app needs": every permission the driver app uses, asked one after another from one
/// place when the dashboard opens (and any time from Settings → App permissions), so a call, a photo or
/// a trip tap never stops on a surprise prompt. Call permissions are tagged "For calls".
class PermissionsSheet extends StatefulWidget {
  const PermissionsSheet({super.key, required this.permissions});
  final AppPermissions permissions;

  /// Dashboard launch: offered once per app launch, and only while something has never been asked.
  /// Returns true when the sheet was shown.
  static Future<bool> showIfNeeded(BuildContext context, {AppPermissions? permissions}) async {
    if (AppPermissions.offeredThisLaunch) return false;
    final p = permissions ?? AppPermissions();
    await p.refresh();
    if (!p.hasUnasked || !context.mounted) return false;
    AppPermissions.offeredThisLaunch = true;
    await show(context, permissions: p);
    return true;
  }

  /// Settings → App permissions: always opens.
  static Future<void> show(BuildContext context, {AppPermissions? permissions}) async {
    final p = permissions ?? AppPermissions();
    await p.refresh();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (_) => PermissionsSheet(permissions: p),
    );
  }

  @override
  State<PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<PermissionsSheet> {
  bool _busy = false;
  AppPermissions get p => widget.permissions;

  Future<void> _allowAll() async {
    setState(() => _busy = true);
    await p.requestAll(onStep: (_) {
      if (mounted) setState(() {});
    });
    await p.refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _one(AppPermissionItem i) async {
    setState(() => _busy = true);
    await p.requestOne(i);
    await p.refresh();
    if (mounted) setState(() => _busy = false);
  }

  (String, Color) _chip(AppPermStatus s) => switch (s) {
        AppPermStatus.granted => ('Allowed', const Color(0xFF15803D)),
        AppPermStatus.notAsked => ('Not asked yet', const Color(0xFF64748B)),
        AppPermStatus.denied => ('Not allowed', const Color(0xFFB45309)),
        AppPermStatus.blocked => ('Blocked in Settings', const Color(0xFFB91C1C)),
      };

  @override
  Widget build(BuildContext context) {
    final canAsk = p.items.any((i) => !i.granted && !i.blocked);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          key: const Key('permissionsSheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Allow what the app needs', style: AppText.titleLg),
                const SizedBox(height: 4),
                Text('So calls, chat, photos and your trips work without stopping on a question. You can change any of these later in Settings.',
                    style: AppText.bodyMd.copyWith(color: const Color(0xFF64748B))),
              ]),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [for (final i in p.items) _row(i)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('permNotNow'),
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(p.allGranted ? 'Close' : 'Not now'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (canAsk)
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('permAllowAll'),
                      onPressed: _busy ? null : _allowAll,
                      child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Allow all'),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppPermissionItem i) {
    final (label, color) = _chip(i.status);
    return Container(
      key: Key('permRow_${i.key}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadii.sm)),
          child: Icon(i.icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(i.title, style: AppText.labelLg),
              if (i.forCalls)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(AppRadii.pill)),
                  child: const Text('For calls', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                ),
            ]),
            const SizedBox(height: 2),
            Text(i.reason, style: AppText.bodySm.copyWith(color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            Row(children: [
              Text(label, key: Key('permStatus_${i.key}'), style: AppText.labelMd.copyWith(color: color)),
              const Spacer(),
              if (i.blocked)
                TextButton(key: Key('permOpenSettings_${i.key}'), onPressed: () => p.backend.openSettings(), child: const Text('Open settings'))
              else if (!i.granted)
                TextButton(key: Key('permAllow_${i.key}'), onPressed: _busy ? null : () => _one(i), child: const Text('Allow')),
            ]),
          ]),
        ),
      ]),
    );
  }
}
