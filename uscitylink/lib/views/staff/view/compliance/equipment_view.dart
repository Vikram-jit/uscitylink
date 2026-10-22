import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Compliance → Equipment: tractor and trailer measurements the scale agent needs for the bridge
/// formula, trailer position (KPRA), ratings and slide estimates. Same data as the web page;
/// bulk CSV import stays on the web.
class EquipmentView extends StatefulWidget {
  const EquipmentView({super.key});

  @override
  State<EquipmentView> createState() => _EquipmentViewState();
}

class _EquipmentViewState extends State<EquipmentView> with SingleTickerProviderStateMixin {
  final ComplianceController _controller = Get.put(ComplianceController());
  late final TabController _tabs = TabController(length: 2, vsync: this);

  String get _kind => _tabs.index == 0 ? 'trailer' : 'tractor';

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
    _controller.loadEquipment();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(EquipmentProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Remove ${p.kind} ${p.unitNumber}?'),
        content: const Text('Scale tickets for this unit will no longer use its measurements.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StaffColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await _controller.deleteEquipment(p);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        floatingActionButton: StaffFab(
          heroTag: 'equipment-add',
          label: _kind == 'trailer' ? 'Add trailer' : 'Add tractor',
          icon: Icons.add_rounded,
          onPressed: () => Get.to(() => EquipmentFormView(kind: _kind)),
        ),
        body: Column(
          children: [
            StaffHeader(
              title: 'Equipment',
              subtitle: 'Axle spacing, KPRA, tandem holes, ratings',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
              bottom: StaffSegmentedTabs(controller: _tabs, labels: const ['Trailers', 'Tractors']),
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: _controller.loadEquipment,
                child: Obx(() {
                  final items = _controller.equipment.where((e) => e.kind == _kind).toList();
                  if (_controller.equipmentLoading.value && _controller.equipment.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
                  }
                  if (items.isEmpty) {
                    return StaffEmptyState(
                      icon: _kind == 'trailer' ? Icons.rv_hookup_rounded : Icons.local_shipping_outlined,
                      title: 'No ${_kind}s yet',
                      message: 'Add them here, or import a spreadsheet on the web.',
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 96),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final v = p.values;
                      final summary = p.kind == 'trailer'
                          ? [
                              'KPRA ${v['kpra_ft'] ?? '—'} ft',
                              'spread ${v['trailer_spread_ft'] ?? '—'} ft',
                              'holes ${v['holes_forward_available'] ?? '—'}/${v['holes_back_available'] ?? '—'}',
                            ].join(' · ')
                          : [
                              'steer→drive ${v['steer_to_drive_center_ft'] ?? '—'} ft',
                              'spread ${v['drive_spread_ft'] ?? '—'} ft',
                              'ratings ${lb(v['steer_rating_lb'])}/${lb(v['drive_rating_lb'])}',
                            ].join(' · ');
                      return StaffListCard(
                        dismissKey: Key('eq-${p.id}'),
                        onDismissed: null,
                        leading: StaffAvatar(
                          name: p.unitNumber,
                          icon: p.kind == 'trailer' ? Icons.rv_hookup_rounded : Icons.local_shipping_rounded,
                        ),
                        title: p.unitNumber,
                        subtitle: summary,
                        chips: [
                          if (p.kind == 'trailer')
                            p.values['lb_per_hole'] != null
                                ? StaffPill(
                                    label: '${lb(p.values['lb_per_hole'])} lb/hole · ${p.samples} reweigh${p.samples == 1 ? '' : 's'}',
                                    color: StaffColors.success,
                                  )
                                : const StaffPill(label: 'lb/hole not measured yet', color: StaffColors.textMuted),
                        ],
                        onTap: () => Get.to(() => EquipmentFormView(kind: p.kind, profile: p, onDelete: () => _confirmDelete(p))),
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

/// Add / edit one tractor or trailer.
class EquipmentFormView extends StatefulWidget {
  final String kind;
  final EquipmentProfile? profile;
  final VoidCallback? onDelete;

  const EquipmentFormView({super.key, required this.kind, this.profile, this.onDelete});

  @override
  State<EquipmentFormView> createState() => _EquipmentFormViewState();
}

class _EquipmentFormViewState extends State<EquipmentFormView> {
  final ComplianceController _controller = Get.find<ComplianceController>();
  late final TextEditingController _unit = TextEditingController(text: widget.profile?.unitNumber ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.profile?.notes ?? '');
  late final Map<String, TextEditingController> _fields = {
    for (final f in widget.kind == 'tractor' ? tractorFields : trailerFields)
      f.key: TextEditingController(text: widget.profile?.values[f.key]?.toString() ?? ''),
  };

  List<EquipmentField> get _defs => widget.kind == 'tractor' ? tractorFields : trailerFields;

  @override
  void dispose() {
    _unit.dispose();
    _notes.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final unit = _unit.text.trim().toUpperCase();
    if (unit.isEmpty) {
      Get.snackbar('Equipment', 'Enter the unit number', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final values = <String, num?>{};
    for (final f in _defs) {
      final raw = _fields[f.key]!.text.trim();
      values[f.key] = raw.isEmpty ? null : num.tryParse(raw);
    }
    final ok = await _controller.saveEquipment(EquipmentProfile(
      id: widget.profile?.id,
      kind: widget.kind,
      unitNumber: unit,
      values: values,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
    if (ok) Get.back();
  }

  InputDecoration _field(String label, {String? help}) => InputDecoration(
        labelText: label,
        helperText: help,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.profile != null;
    final layoutKeys = widget.kind == 'tractor'
        ? ['steer_to_drive_center_ft', 'drive_spread_ft', 'kingpin_to_drive_center_ft', 'fifth_wheel_range_in']
        : ['axle_count', 'length_ft', 'kpra_ft', 'trailer_spread_ft'];
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: StaffColors.hairline))),
            child: Row(
              children: [
                if (editing && widget.onDelete != null)
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      widget.onDelete!();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: StaffColors.danger),
                  ),
                const Spacer(),
                Obx(() => FilledButton.icon(
                      onPressed: _controller.busy.value ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: StaffColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
                      ),
                    )),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            StaffHeader(
              title: editing ? '${widget.kind == 'tractor' ? 'Tractor' : 'Trailer'} ${widget.profile!.unitNumber}' : 'Add ${widget.kind}',
              subtitle: 'Leave a field empty if you do not know it',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  TextField(
                    controller: _unit,
                    enabled: !editing,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _field('Unit number', help: 'As printed on the scale ticket / yard'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(widget.kind == 'tractor' ? 'Axle layout (bridge formula)' : 'Axle layout',
                      style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final f in _defs.where((f) => layoutKeys.contains(f.key))) _numberField(f),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.kind == 'tractor' ? 'Ratings' : 'Tandems & ratings',
                      style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                  const SizedBox(height: AppSpacing.sm),
                  for (final f in _defs.where((f) => !layoutKeys.contains(f.key))) _numberField(f),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(controller: _notes, decoration: _field('Notes'), maxLines: 2),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(EquipmentField f) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextField(
          controller: _fields[f.key],
          keyboardType: TextInputType.numberWithOptions(decimal: !f.integer),
          decoration: _field(f.label, help: f.help),
        ),
      );
}
