import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// The route a driver is on: every state in driving order with the road type, plus permits.
/// Scale tickets are checked against the rules for each segment (lowest limit wins); saving
/// re-checks the driver's open tickets. Pops `true` when saved.
class TripEditorView extends StatefulWidget {
  final String driverId;
  final String? driverName;
  final String? defaultTruck;
  final String? defaultTrailer;

  const TripEditorView({super.key, required this.driverId, this.driverName, this.defaultTruck, this.defaultTrailer});

  @override
  State<TripEditorView> createState() => _TripEditorViewState();
}

class _TripEditorViewState extends State<TripEditorView> {
  final ComplianceController _controller = Get.find<ComplianceController>();
  DriverTrip? _trip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final existing = await _controller.driverTrip(widget.driverId);
    if (!mounted) return;
    setState(() {
      _trip = existing ?? DriverTrip(truck: widget.defaultTruck ?? '', trailer: widget.defaultTrailer ?? '');
      _loading = false;
    });
  }

  Future<void> _save() async {
    final trip = _trip!;
    if (trip.segments.any((s) => s.state.isEmpty)) {
      Get.snackbar('Route', 'Choose a state for every segment', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (await _controller.saveDriverTrip(widget.driverId, trip)) Get.back(result: true);
  }

  Future<void> _closeTrip() async {
    if (await _controller.closeDriverTrip(widget.driverId)) Get.back(result: true);
  }

  InputDecoration _field(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        bottomNavigationBar: _loading
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: StaffColors.hairline))),
                  child: Row(
                    children: [
                      if (_trip?.exists == true)
                        TextButton(
                          onPressed: _closeTrip,
                          style: TextButton.styleFrom(foregroundColor: StaffColors.textBody),
                          child: const Text('Close trip'),
                        ),
                      const Spacer(),
                      Obx(() => FilledButton.icon(
                            onPressed: _controller.busy.value ? null : _save,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save route'),
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
              title: 'Route',
              subtitle: widget.driverName,
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: StaffColors.primary))
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: StaffColors.sky.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Text(
                            'List every state in driving order with the road type. Tickets are checked against the rules '
                            'for each segment and the lowest limit applies. Saving re-checks this driver\'s open tickets.',
                            style: AppText.bodySm.copyWith(color: StaffColors.textBody),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _sectionTitle('Trip'),
                        Row(children: [
                          Expanded(child: _text('Tractor #', _trip!.truck, (v) => _trip!.truck = v)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _text('Trailer #', _trip!.trailer, (v) => _trip!.trailer = v)),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        Row(children: [
                          Expanded(child: _text('Origin', _trip!.origin, (v) => _trip!.origin = v)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _text('Destination', _trip!.destination, (v) => _trip!.destination = v)),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        _text('Cargo / commodity', _trip!.cargo, (v) => _trip!.cargo = v),
                        const SizedBox(height: AppSpacing.lg),
                        _sectionTitle('Route segments'),
                        for (var i = 0; i < _trip!.segments.length; i++) _segment(i),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _trip!.segments.add(TripSegment())),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add segment'),
                            style: TextButton.styleFrom(foregroundColor: StaffColors.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _sectionTitle('Permits'),
                        if (_trip!.permits.isEmpty)
                          Text('No permits. A valid permit replaces the limits it lists for that state; an expired one is ignored.',
                              style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                        for (var i = 0; i < _trip!.permits.length; i++) _permit(i),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _trip!.permits.add(TripPermit())),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add permit'),
                            style: TextButton.styleFrom(foregroundColor: StaffColors.primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
      );

  Widget _text(String label, String value, ValueChanged<String> onChanged, {TextInputType? keyboard}) => TextFormField(
        initialValue: value,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.characters,
        decoration: _field(label),
        onChanged: onChanged,
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: StaffColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: StaffColors.hairline),
        ),
        child: child,
      );

  Widget _stateDropdown(String value, ValueChanged<String> onChanged) => DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: _field('State'),
        items: [for (final s in usStates) DropdownMenuItem(value: s, child: Text(s))],
        onChanged: (v) => setState(() => onChanged(v ?? '')),
      );

  Widget _segment(int i) {
    final seg = _trip!.segments[i];
    // Keyed to the segment so text fields follow it when segments are moved or removed
    return KeyedSubtree(key: ObjectKey(seg), child: _card(Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: StaffColors.primary,
              child: Text('${i + 1}', style: AppText.labelMd.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 2, child: _stateDropdown(seg.state, (v) => seg.state = v)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: seg.roadClass,
                isExpanded: true,
                decoration: _field('Road type'),
                items: [for (final e in roadClassLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => seg.roadClass = v ?? seg.roadClass),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: seg.note,
                decoration: _field('Note', hint: 'e.g. I-10 west'),
                onChanged: (v) => seg.note = v,
              ),
            ),
            IconButton(
              tooltip: 'Move up',
              onPressed: i == 0
                  ? null
                  : () => setState(() {
                        final s = _trip!.segments.removeAt(i);
                        _trip!.segments.insert(i - 1, s);
                      }),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: _trip!.segments.length == 1 ? null : () => setState(() => _trip!.segments.removeAt(i)),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ],
    )));
  }

  Widget _permit(int i) {
    final p = _trip!.permits[i];
    num? parse(String v) => v.trim().isEmpty ? null : num.tryParse(v.trim());
    return KeyedSubtree(key: ObjectKey(p), child: _card(Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _stateDropdown(p.state, (v) => p.state = v)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: TextFormField(initialValue: p.number, decoration: _field('Permit #'), onChanged: (v) => p.number = v),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: () => setState(() => _trip!.permits.removeAt(i)),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(p.expiresAt) ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) setState(() => p.expiresAt = DateFormat('yyyy-MM-dd').format(picked));
          },
          child: InputDecorator(
            decoration: _field('Expires'),
            child: Text(p.expiresAt.isEmpty ? 'Choose date' : p.expiresAt,
                style: AppText.bodyMd.copyWith(color: p.expiresAt.isEmpty ? StaffColors.textMuted : StaffColors.textStrong)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: TextFormField(
                    initialValue: p.grossLb?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: _field('Gross (lb)'),
                    onChanged: (v) => p.grossLb = parse(v))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: TextFormField(
                    initialValue: p.tandemLb?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: _field('Tandem (lb)'),
                    onChanged: (v) => p.tandemLb = parse(v))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: TextFormField(
                    initialValue: p.singleAxleLb?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: _field('Single (lb)'),
                    onChanged: (v) => p.singleAxleLb = parse(v))),
          ],
        ),
      ],
    )));
  }
}
