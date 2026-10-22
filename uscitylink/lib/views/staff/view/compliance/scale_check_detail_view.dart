import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/view/compliance/trip_editor_view.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

const _statusExplanations = {
  'PASS_PRELIMINARY': 'Every weight, the bridge formula and the trailer position are within the route\'s limits. Release the load when you are ready.',
  'ROUTE_REVIEW_REQUIRED': 'The weights look fine, but the route or the state rules for it are not verified. Check the route before releasing.',
  'BRIDGE_REVIEW': 'The weights look fine, but axle spacing / trailer position could not be checked. Check the equipment before releasing.',
  'ADJUST_AND_REWEIGH': 'Something is over a limit. The driver was told what to adjust; a new ticket will be checked when it arrives.',
  'OVER_GROSS': 'The load is over gross weight. Sliding cannot fix it — cargo has to come off before a new ticket.',
  'OCR_UNCERTAIN': 'The ticket could not be read reliably. Ask for a clearer photo, or correct the weights on the web.',
};

/// One scale ticket in full, with the dispatcher's actions (same as the card in the web chat).
class ScaleCheckDetailView extends StatefulWidget {
  final ScaleCheck check;
  const ScaleCheckDetailView({super.key, required this.check});

  @override
  State<ScaleCheckDetailView> createState() => _ScaleCheckDetailViewState();
}

class _ScaleCheckDetailViewState extends State<ScaleCheckDetailView> {
  final ComplianceController _controller = Get.find<ComplianceController>();
  late ScaleCheck _check = widget.check;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final fresh = await _controller.reloadCheck(_check);
    if (fresh != null && mounted) setState(() => _check = fresh);
  }

  Future<void> _release() async {
    String? note;
    if (_check.releaseNeedsNote) {
      note = await askForNote(
        context,
        title: 'Release without full verification',
        explanation: _check.status == 'ROUTE_REVIEW_REQUIRED'
            ? 'The weights are within limits, but the route or its state rules could not be verified. Note what you checked; it is kept with your name.'
            : 'The weights are within limits, but the axle spacing / trailer position could not be verified. Note what you checked; it is kept with your name.',
        label: 'What did you check?',
        hint: 'e.g. Route is I-10 only, confirmed with the driver.',
        confirmLabel: 'Release',
        confirmColor: StaffColors.success,
      );
      if (note == null) return;
    }
    if (await _controller.decide(_check, 'approve', note: note)) await _reload();
  }

  Future<void> _reject() async {
    final note = await askForNote(
      context,
      title: "Don't release this load",
      label: 'Note for the driver',
      hint: 'e.g. Trailer position needs checking — call dispatch before you move.',
      confirmLabel: 'Send to driver',
      confirmColor: StaffColors.danger,
    );
    if (note == null) return;
    if (await _controller.decide(_check, 'reject', note: note)) await _reload();
  }

  Future<void> _recordAdjustment() async {
    final suggested = _check.adjustments.firstWhereOrNull((a) => a.action != 'rework_cargo');
    String action = suggested?.action ?? 'tandems_forward';
    final holes = TextEditingController(text: suggested?.holes?.toString() ?? '');
    bool parked = false;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('What did the driver adjust?', style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
              const SizedBox(height: AppSpacing.base),
              DropdownButtonFormField<String>(
                value: action,
                isExpanded: true,
                decoration: _field('Adjustment'),
                items: [
                  for (final e in adjustmentLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setSheet(() => action = v ?? action),
              ),
              if (action.startsWith('tandems')) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: holes,
                  keyboardType: TextInputType.number,
                  decoration: _field('Holes moved', helper: "Used to learn this trailer's weight shift per hole"),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: parked,
                activeColor: StaffColors.primary,
                onChanged: (v) => setSheet(() => parked = v ?? false),
                title: Text('Driver confirmed they were parked and the vehicle was secured', style: AppText.bodyMd),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: StaffColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: !parked ? null : () => Navigator.pop(ctx, true),
                child: const Text('Record adjustment'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final count = int.tryParse(holes.text.trim());
    if (await _controller.recordAdjustment(_check, action, action.startsWith('tandems') ? count : null)) await _reload();
  }

  Future<void> _openRoute() async {
    if (_check.driverId == null) return;
    final saved = await Get.to<bool>(() => TripEditorView(
          driverId: _check.driverId!,
          driverName: _check.driverName,
          defaultTruck: _check.tractorUnit,
          defaultTrailer: _check.trailerUnit,
        ));
    if (saved == true) await _reload();
  }

  InputDecoration _field(String label, {String? helper}) => InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: StaffColors.canvas,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final c = _check;
    final segments = c.segments;
    final routeText = c.routeKnown && segments.isNotEmpty
        ? segments
            .map((s) => '${s['state']} ${roadClassLabels[s['road_class']] ?? s['road_class']}${s['permit'] != null ? ' (permit)' : ''}')
            .join(' → ')
        : 'Not entered';
    final kpraMax = c.kpra['max_ft'];
    final kpraFt = c.kpra['kpra_ft'];
    final kpraText = c.kpra['over_ft'] != null
        ? '$kpraFt ft — ${c.kpra['over_ft']} ft over the $kpraMax ft limit'
        : kpraMax != null
            ? (kpraFt != null ? '$kpraFt of $kpraMax ft allowed' : 'Not verified (trailer data missing)')
            : (c.kpra['verified'] == true ? 'No KPRA limit on this route' : 'Not verified');

    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        bottomNavigationBar: _actionBar(),
        body: Column(
          children: [
            StaffHeader(
              title: c.driverName ?? 'Scale check',
              subtitle: [if (c.truck != null) 'Truck ${c.truck}', if (c.ticketNumber != null) 'Ticket #${c.ticketNumber}'].join(' · '),
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
              actions: [
                Obx(() => StaffGlassButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Re-check',
                      onTap: _controller.busy.value
                          ? null
                          : () async {
                              if (await _controller.recheck(_check)) await _reload();
                            },
                    )),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  children: [
                    StaffSectionCard(
                      title: 'Result',
                      icon: Icons.fact_check_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            ScaleStatusPill(check: c),
                            ApprovalPill(check: c),
                            if (c.previousCheckId != null) const StaffPill(label: 'Reweigh', color: StaffColors.textBody),
                          ]),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_statusExplanations[c.status] ?? '', style: AppText.bodyMd.copyWith(color: StaffColors.textBody)),
                          if (c.approvalNote != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text('Note: ${c.approvalNote}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    StaffSectionCard(title: 'Weights', icon: Icons.scale_rounded, child: ScaleWeightsTable(check: c)),
                    StaffSectionCard(
                      title: 'Route & rules',
                      icon: Icons.route_rounded,
                      trailing: c.driverId == null
                          ? null
                          : TextButton.icon(
                              onPressed: _openRoute,
                              icon: const Icon(Icons.edit_road_rounded, size: 18),
                              label: Text(c.routeKnown ? 'Edit route' : 'Set route'),
                              style: TextButton.styleFrom(foregroundColor: StaffColors.primary),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routeText, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                          if (c.missingRules.isNotEmpty) _warn('No rules on file for ${c.missingRules.join(', ')}'),
                          if (c.unverifiedRules.isNotEmpty) _warn('Rules not reviewed: ${c.unverifiedRules.join(', ')}'),
                          if (c.ruleSetVersion != null) ...[
                            const SizedBox(height: 4),
                            Text('Rules used: ${c.ruleSetVersion}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    StaffSectionCard(
                      title: 'Equipment & axles',
                      icon: Icons.local_shipping_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Tractor', c.tractorUnit ?? '—'),
                          _row('Trailer', c.trailerUnit ?? '—'),
                          _row(
                            'Bridge formula',
                            c.bridge.isEmpty
                                ? 'Not checked (axle spacing unknown)'
                                : c.bridgeOver.isEmpty
                                    ? 'All ${c.bridge.length} axle groups within'
                                    : c.bridgeOver.map((g) => 'axles ${g['axles']} +${lb(g['over_lb'] as num?)} lb').join(', '),
                            danger: c.bridgeOver.isNotEmpty,
                          ),
                          _row('Trailer position (KPRA)', kpraText, danger: c.kpra['over_ft'] != null),
                          if (c.equipmentMissing.isNotEmpty) _warn('Missing: ${c.equipmentMissing.take(3).join(', ')}'),
                        ],
                      ),
                    ),
                    if (c.adjustments.isNotEmpty)
                      StaffSectionCard(
                        title: 'Suggested (estimate — reweigh required)',
                        icon: Icons.tune_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final a in c.adjustments)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(a.action == 'rework_cargo' ? Icons.warning_amber_rounded : Icons.swap_vert_rounded,
                                        size: 18, color: a.action == 'rework_cargo' ? StaffColors.danger : StaffColors.primary),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: Text(a.label, style: AppText.bodyMd.copyWith(color: StaffColors.textBody))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (c.adjustmentMade.isNotEmpty || c.prediction.isNotEmpty)
                      StaffSectionCard(
                        title: 'Adjustment & reweigh',
                        icon: Icons.published_with_changes_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.adjustmentMade.isNotEmpty)
                              Text(
                                'Adjusted: ${adjustmentLabels[c.adjustmentMade['action']] ?? c.adjustmentMade['action']}'
                                '${c.adjustmentMade['holes'] != null ? ', ${c.adjustmentMade['holes']} hole(s)' : ''} · parked & secured confirmed',
                                style: AppText.bodyMd.copyWith(color: StaffColors.textBody),
                              ),
                            if (c.prediction.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Reweigh vs. adjustment: ${c.prediction['note'] ?? ''}'
                                '${c.prediction['learned_lb_per_hole'] != null ? ' Learned ~${lb(c.prediction['learned_lb_per_hole'] as num?)} lb/hole.' : ''}',
                                style: AppText.bodyMd.copyWith(
                                  color: c.prediction['mismatch'] == true ? StaffColors.warning : StaffColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (c.assumptions.isNotEmpty)
                      StaffSectionCard(
                        title: 'Not verified by the agent',
                        icon: Icons.info_outline_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final a in c.assumptions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $a', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                              ),
                          ],
                        ),
                      ),
                    if ((c.driverMessage ?? '').isNotEmpty)
                      StaffSectionCard(
                        title: 'Sent to driver',
                        icon: Icons.sms_outlined,
                        child: Text(c.driverMessage!, style: AppText.bodyMd.copyWith(color: StaffColors.textBody)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _actionBar() {
    final c = _check;
    final canAdjust = c.status == 'ADJUST_AND_REWEIGH' && c.adjustmentMade.isEmpty;
    if (!c.isPending && !canAdjust) return null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: StaffColors.hairline)),
        ),
        child: Obx(() {
          final busy = _controller.busy.value;
          if (!c.isPending) {
            return FilledButton.icon(
              onPressed: busy ? null : _recordAdjustment,
              icon: const Icon(Icons.build_rounded),
              label: const Text('Record adjustment'),
              style: FilledButton.styleFrom(backgroundColor: StaffColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            );
          }
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StaffColors.danger,
                    side: const BorderSide(color: StaffColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: busy ? null : _release,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Release load'),
                  style: FilledButton.styleFrom(backgroundColor: StaffColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _row(String label, String value, {bool danger = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(label, style: AppText.bodySm.copyWith(color: StaffColors.textMuted))),
            Expanded(
              child: Text(value,
                  style: AppText.bodyMd.copyWith(
                    color: danger ? StaffColors.danger : StaffColors.textStrong,
                    fontWeight: danger ? FontWeight.w600 : FontWeight.w400,
                  )),
            ),
          ],
        ),
      );

  Widget _warn(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: StaffColors.warning),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: AppText.bodySm.copyWith(color: StaffColors.warning))),
          ],
        ),
      );
}
