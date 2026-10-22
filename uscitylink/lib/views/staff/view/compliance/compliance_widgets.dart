import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Shared pieces for the staff Compliance screens.

final _lbFormat = NumberFormat.decimalPattern('en_US');
String lb(num? v) => v == null ? '—' : _lbFormat.format(v.round());

Color scaleStatusColor(String status) {
  switch (status) {
    case 'PASS_PRELIMINARY':
      return StaffColors.success;
    case 'ROUTE_REVIEW_REQUIRED':
    case 'BRIDGE_REVIEW':
      return StaffColors.sky;
    case 'ADJUST_AND_REWEIGH':
      return StaffColors.warning;
    case 'OVER_GROSS':
      return StaffColors.danger;
    default:
      return StaffColors.textMuted;
  }
}

class ScaleStatusPill extends StatelessWidget {
  final ScaleCheck check;
  const ScaleStatusPill({super.key, required this.check});

  @override
  Widget build(BuildContext context) => StaffPill(label: check.statusLabel, color: scaleStatusColor(check.status));
}

/// Dispatch decision as a pill: Waiting / Released by … / Not released / Replaced by reweigh.
class ApprovalPill extends StatelessWidget {
  final ScaleCheck check;
  const ApprovalPill({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    final time = check.approvedAt != null ? ' ${DateFormat('h:mm a').format(check.approvedAt!)}' : '';
    switch (check.approvalStatus) {
      case 'pending':
        return const StaffPill(label: 'Waiting for dispatch', color: StaffColors.sky, icon: Icons.schedule_rounded);
      case 'approved':
        return StaffPill(
            label: 'Released by ${check.approvedByName ?? 'staff'}$time', color: StaffColors.success, icon: Icons.check_rounded);
      case 'rejected':
        return StaffPill(label: 'Not released by ${check.approvedByName ?? 'staff'}', color: StaffColors.danger, icon: Icons.block_rounded);
      case 'superseded':
        return const StaffPill(label: 'Replaced by reweigh', color: StaffColors.textMuted);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Steer / drive / trailer / gross with how far over or how much room each has.
class ScaleWeightsTable extends StatelessWidget {
  final ScaleCheck check;
  const ScaleWeightsTable({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in scaleGroups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(scaleGroupLabels[g]!, style: AppText.bodyMd.copyWith(color: StaffColors.textMuted)),
                ),
                Expanded(
                  child: Text(
                    '${lb(check.weights[g])} lb',
                    style: AppText.numeric(AppText.titleMd).copyWith(color: StaffColors.textStrong),
                  ),
                ),
                if ((check.overages[g] ?? 0) > 0)
                  Text('+${lb(check.overages[g])} over',
                      style: AppText.labelLg.copyWith(color: StaffColors.danger))
                else if (check.headroom[g] != null)
                  Text('${lb(check.headroom[g])} room', style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
              ],
            ),
          ),
      ],
    );
  }
}

/// White card with a title, used to group a section of the detail screen.
class StaffSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const StaffSectionCard({super.key, required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: StaffColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppText.titleMd.copyWith(color: StaffColors.textStrong))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Text-entry dialog for notes (release / reject). Returns the note, or null if cancelled.
Future<String?> askForNote(
  BuildContext context, {
  required String title,
  required String label,
  String? explanation,
  String? hint,
  String confirmLabel = 'Save',
  Color confirmColor = StaffColors.primary,
  int minLength = 1,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final length = controller.text.trim().length;
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          title: Text(title, style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (explanation != null) ...[
                Text(explanation, style: AppText.bodyMd.copyWith(color: StaffColors.textBody)),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  helperText: minLength > 1 ? '$length/$minLength characters minimum' : null,
                  filled: true,
                  fillColor: StaffColors.canvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: confirmColor),
              onPressed: length < minLength ? null : () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    ),
  );
}
