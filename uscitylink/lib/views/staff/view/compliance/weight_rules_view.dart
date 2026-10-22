import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compliance → Weight rules: the versioned legal limits each route segment is checked against,
/// with the named review sign-off. New versions / new state rules are added on the web (they need
/// the statute citation and an audit note).
class WeightRulesView extends StatefulWidget {
  const WeightRulesView({super.key});

  @override
  State<WeightRulesView> createState() => _WeightRulesViewState();
}

class _WeightRulesViewState extends State<WeightRulesView> {
  final ComplianceController _controller = Get.put(ComplianceController());

  @override
  void initState() {
    super.initState();
    _controller.loadRules();
  }

  Future<void> _confirmReview(WeightRuleSet r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Mark ${r.jurisdiction} v${r.version} reviewed?'),
        content: const Text(
            'Only confirm if you checked these limits against the current statute or state DOT. Your name is recorded on this version.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StaffColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark reviewed'),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.reviewRule(r);
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
              title: 'Weight rules',
              subtitle: 'Versioned limits used for every route segment',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: _controller.loadRules,
                child: Obx(() {
                  if (_controller.rulesLoading.value && _controller.rules.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
                  }
                  if (_controller.rules.isEmpty) {
                    return const StaffEmptyState(icon: Icons.gavel_rounded, title: 'No rules yet');
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.base),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: StaffColors.sky.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Text(
                          'A state with no reviewed rules sends its tickets to route review. Add a new state or a new version on the web.',
                          style: AppText.bodySm.copyWith(color: StaffColors.textBody),
                        ),
                      ),
                      for (final r in _controller.rules) _ruleCard(r),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleCard(WeightRuleSet r) {
    final due = r.reviewDue == null ? null : DateFormat('MMM d, yyyy').format(r.reviewDue!);
    return Opacity(
      opacity: r.active ? 1 : 0.55,
      child: StaffSectionCard(
        title: '${r.jurisdiction}${r.roadClass != 'interstate' ? ' ${roadClassLabels[r.roadClass] ?? r.roadClass}' : ''} v${r.version}',
        icon: Icons.gavel_rounded,
        trailing: r.active
            ? StaffPill(
                label: r.verified ? 'Reviewed' : (r.reviewDue != null ? 'Review overdue' : 'Not reviewed'),
                color: r.verified ? StaffColors.success : StaffColors.warning,
              )
            : const StaffPill(label: 'Retired', color: StaffColors.textMuted),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.name, style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.xs,
              children: [
                _metric('Single', '${lb(r.singleAxle)} lb'),
                _metric('Tandem', '${lb(r.tandem)} lb'),
                _metric('Gross', '${lb(r.gross)} lb'),
                _metric('KPRA', r.kpraMax == null ? 'none' : '${r.kpraMax} ft'),
                _metric('Bridge', r.bridgeFormula ? 'yes' : 'no'),
              ],
            ),
            if (r.citation != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(r.citation!, style: AppText.bodySm.copyWith(color: StaffColors.textBody)),
            ],
            if (r.verified && r.reviewedByName != null)
              Text('Reviewed by ${r.reviewedByName}${due != null ? ' · due $due' : ''}',
                  style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
            if (r.active)
              Row(
                children: [
                  if (r.sourceUrl != null)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(r.sourceUrl!), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Official source'),
                      style: TextButton.styleFrom(foregroundColor: StaffColors.primary, padding: EdgeInsets.zero),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _confirmReview(r),
                    style: TextButton.styleFrom(foregroundColor: StaffColors.primary),
                    child: Text(r.verified ? 'Re-review' : 'Mark reviewed'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
          Text(value, style: AppText.numeric(AppText.titleMd).copyWith(color: StaffColors.textStrong)),
        ],
      );
}
