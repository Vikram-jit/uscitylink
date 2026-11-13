import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/services/staff/staff_api_client.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/loads/live_panel.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/view/loads/staff_add_load_view.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// One load: its legs, what to do next on each, miles, history and the shipper's tracking code.
class StaffLoadDetailView extends StatefulWidget {
  const StaffLoadDetailView({super.key, required this.loadId, this.service});
  final int loadId;
  final LoadsService? service;

  @override
  State<StaffLoadDetailView> createState() => _StaffLoadDetailViewState();
}

class _StaffLoadDetailViewState extends State<StaffLoadDetailView> {
  late final LoadsService _svc = widget.service ?? LoadsService();
  LoadDetail? _d;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _svc.detail(widget.loadId);
      if (mounted) setState(() => (_d = d, _error = null));
    } catch (e) {
      if (mounted) setState(() => _error = errText(e));
    }
  }

  Future<void> _run(Future<String> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final msg = await op();
      if (mounted) snack(context, msg);
      await _load();
    } catch (e) {
      if (mounted) snack(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end(LoadLeg l) async {
    final ok = await confirmDialog(context,
        title: 'End leg ${l.legNo}?',
        body: 'Mark ${_d!.driverName(l)}\'s leg delivered now. It leaves the driver\'s app and the driver is told.',
        yes: 'End load');
    if (ok) _run(() => _svc.endLeg(widget.loadId, l.id));
  }

  Future<void> _complete(LoadLeg l) => _run(() async {
        try {
          return await _svc.completeLeg(l.id);
        } on StaffApiError catch (e) {
          if (!e.message.toLowerCase().contains('invoice')) rethrow;
          final no = await _ask('Load # / invoice #', 'This older load has no number yet. Type it to finish.');
          if (no == null || no.isEmpty) return 'Not completed';
          return _svc.completeLeg(l.id, invoiceNo: no);
        }
      });

  Future<String?> _ask(String title, String hint, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('OK'))],
      ),
    );
  }

  /// More than one delivered leg: complete one by one, or all.
  Future<void> _completeDialog(List<LoadLeg> legs) async {
    if (legs.length == 1) return _complete(legs.first);
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(builder: (dc, set) {
        return AlertDialog(
          key: const Key('completeDialog'),
          title: const Text('Mark completed'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final l in legs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('Leg ${l.legNo} · ${_d!.driverName(l)}'),
                subtitle: Text('${l.first?.title ?? ''} → ${l.last?.title ?? ''}'),
                trailing: TextButton(
                  key: Key('completeLeg_${l.id}'),
                  onPressed: () async {
                    Navigator.pop(dc);
                    await _complete(l);
                  },
                  child: const Text('Complete'),
                ),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Close')),
            FilledButton(
              key: const Key('completeAll'),
              onPressed: () async {
                Navigator.pop(dc);
                for (final l in legs) {
                  await _complete(l);
                }
              },
              child: const Text('Mark all completed'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _correctTimes(LoadLeg l) async {
    DateTime? started = l.startedAt?.toLocal(), ended = l.endedAt?.toLocal();
    final why = TextEditingController();
    final started0 = started, ended0 = ended;
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(builder: (dc, set) {
        Future<DateTime?> pick(DateTime? cur) async {
          final base = cur ?? DateTime.now();
          final d = await showDatePicker(context: dc, initialDate: base, firstDate: DateTime(2024), lastDate: DateTime(2100));
          if (d == null || !dc.mounted) return null;
          final t = await showTimePicker(context: dc, initialTime: TimeOfDay.fromDateTime(base));
          return t == null ? null : DateTime(d.year, d.month, d.day, t.hour, t.minute);
        }

        return AlertDialog(
          title: Text('Correct times · #${l.tripNo ?? l.legNo}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(dense: true, title: const Text('Started (rolling)'), subtitle: Text(fmtDateTime(started)), trailing: const Icon(Icons.edit_calendar_rounded), onTap: () async {
              final v = await pick(started);
              if (v != null) set(() => started = v);
            }),
            ListTile(dense: true, title: const Text('Ended (delivered / handed over)'), subtitle: Text(fmtDateTime(ended)), trailing: const Icon(Icons.edit_calendar_rounded), onTap: () async {
              final v = await pick(ended);
              if (v != null) set(() => ended = v);
            }),
            TextField(controller: why, decoration: const InputDecoration(labelText: 'Why (kept on the record)', hintText: 'Driver tapped Delivered late')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (why.text.trim().isEmpty) return snack(context, 'Say why the times are changed', error: true);
                final body = <String, dynamic>{'reason': why.text.trim()};
                if (started != started0) body['startedAt'] = started?.toUtc().toIso8601String();
                if (ended != ended0) body['endedAt'] = ended?.toUtc().toIso8601String();
                if (body.length == 1) return snack(context, 'Nothing changed');
                Navigator.pop(dc);
                _run(() => _svc.correctTimes(widget.loadId, l.id, body));
              },
              child: const Text('Save times'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _miles(LoadLeg l) async {
    final m = TextEditingController(text: l.totalMileage == null ? '' : '${l.totalMileage}');
    final n = TextEditingController(text: l.milesNote ?? '');
    await showDialog<void>(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text('Miles · #${l.tripNo ?? l.legNo}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(alignment: Alignment.centerLeft, child: Text('Now: ${fmtMiles(l.totalMileage)} ${l.totalMileage != null ? '(${l.milesSourceLabel})' : (l.milesNote ?? '')}')),
          TextField(controller: m, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Miles')),
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Why (kept on the record)', hintText: 'Samsara offline — odometer photo')),
        ]),
        actions: [
          if (l.milesSource == 'manual')
            TextButton(
              onPressed: () {
                Navigator.pop(dc);
                _run(() => _svc.setMiles(widget.loadId, l.id));
              },
              child: const Text('Use Samsara again'),
            ),
          TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(m.text.trim());
              if (v == null || n.text.trim().isEmpty) return snack(context, 'Type the miles and why', error: true);
              Navigator.pop(dc);
              _run(() => _svc.setMiles(widget.loadId, l.id, miles: v, note: n.text.trim()));
            },
            child: const Text('Save miles'),
          ),
        ],
      ),
    );
  }

  Future<void> _assign(LoadLeg l) async {
    List<TruckPick> trucks = [];
    try {
      trucks = await _svc.truckPicks('');
    } catch (e) {
      return snack(context, errText(e), error: true);
    }
    if (!mounted) return;
    final pick = await showModalBottomSheet<(TruckPick, DriverPick?)>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (c, sc) => ListView(controller: sc, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Pick a truck and driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          for (final t in trucks)
            for (final d in (t.drivers.isEmpty ? <DriverPick?>[null] : t.drivers))
              ListTile(title: Text('Truck ${t.truck}'), subtitle: Text(d?.name ?? 'No driver on this truck'), enabled: d != null, onTap: () => Navigator.pop(c, (t, d))),
        ]),
      ),
    );
    if (pick == null || pick.$2 == null) return;
    final team = pick.$1.drivers.where((x) => x.id != pick.$2!.id).firstOrNull;
    _run(() => _svc.assignLeg(widget.loadId, l.id, driverProfileId: pick.$2!.id, teamDriverProfileId: team?.id, truckNumber: pick.$1.truck));
  }

  String? _link(StaffLoad l) {
    if (l.trackToken == null) return null;
    const base = kTrackingWebsite;
    return base.isEmpty ? null : '$base/track/${l.trackToken}';
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Column(children: [
        StaffHeader(
          title: d == null ? 'Load' : 'Load ${d.load.number}',
          subtitle: d == null ? null : '${d.load.typeLabel} · ${d.load.statusLabel}',
          leadingIcon: Icons.arrow_back_rounded,
          onLeading: () => Navigator.pop(context),
        ),
        Expanded(
          child: d == null
              ? Center(child: _error != null ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!)) : const CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _load, child: _body(d)),
        ),
      ]),
    );
  }

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: StaffColors.card, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: StaffColors.hairline), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _title(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: AppText.titleMd.copyWith(color: StaffColors.textStrong)));

  Widget _body(LoadDetail d) {
    final closed = d.load.isClosed;
    final delivered = d.activeLegs.where((l) => l.isDelivered).toList();
    final link = _link(d.load);
    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
      if (!closed)
        _card([
          _title('Shipper tracking'),
          Row(children: [
            StaffPill(label: 'Code ${d.load.number}', color: StaffColors.primary),
            const Spacer(),
            TextButton.icon(
              key: const Key('shareTracking'),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Share'),
              onPressed: () {
                final text = link != null
                    ? 'Track load ${d.load.number}: $link'
                    : 'Track load ${d.load.number} in the USCityLink app — tap "Track a load" and enter ${d.load.number}.';
                SharePlus.instance.share(ShareParams(text: text));
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link ?? d.load.number));
                snack(context, link != null ? 'Tracking link copied' : 'Load number copied');
              },
            ),
          ]),
          Text('Customers type this load number in "Track a load". It expires when the load is completed.', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
        ]),
      if (delivered.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FilledButton.icon(key: const Key('markCompleted'), onPressed: _busy ? null : () => _completeDialog(delivered), icon: const Icon(Icons.task_alt_rounded), label: Text(delivered.length > 1 ? 'Mark completed (${delivered.length} legs)' : 'Mark completed')),
        ),
      for (final l in d.activeLegs) _legCard(d, l),
      if (d.timing?.deliveredAt != null)
        _card([
          _title('Delivered vs ETA'),
          Text('Delivered ${fmtDateTime(d.timing!.deliveredAt)}'),
          if (d.timing!.lateMinutes != null) Text(d.timing!.lateMinutes! > 0 ? '${fmtMinutes(d.timing!.lateMinutes)} after the appointment' : 'On time'),
          if (d.timing!.etaOffMinutes != null) Text('ETA was off by ${fmtMinutes(d.timing!.etaOffMinutes!.abs())}'),
        ]),
      if (d.segments.isNotEmpty)
        _card([
          _title('Miles · ${fmtMiles(d.milesTotal)} total'),
          if (d.milesMissing > 0) Text('${d.milesMissing} leg(s) have no miles yet', style: AppText.bodySm.copyWith(color: StaffColors.danger)),
          for (final s in d.segments)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Leg ${s.legNo} · ${s.drivers.join(' + ')}${s.truck == null ? '' : ' · Truck ${s.truck}'}\n${s.from} → ${s.to}\n${fmtMiles(s.miles)}${s.milesSource == 'manual' ? ' (typed)' : s.milesSource == 'gps' ? ' (GPS times)' : ''}${s.minutes == null ? '' : ' · ${fmtMinutes(s.minutes)}'}', style: AppText.bodySm.copyWith(color: StaffColors.textBody)),
            ),
        ]),
      if (d.yardVisits.isNotEmpty)
        _card([
          _title('In our yard · ${fmtMinutes(d.yardMinutes)}'),
          for (final v in d.yardVisits) Text('${v.trailer ?? 'Trailer'}: ${fmtDateTime(v.inAt)} → ${v.outAt == null ? 'still there' : fmtDateTime(v.outAt)}', style: AppText.bodySm),
        ]),
      if (d.history.isNotEmpty)
        _card([
          _title('History'),
          for (final h in d.history.reversed.take(40))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${fmtDateTime(h.at)} · Leg ${h.legNo} · ${h.type}${h.to == null ? '' : ' → ${h.to}'}${h.note == null ? '' : ' — ${h.note}'}  (${h.actor})', style: AppText.bodySm.copyWith(color: StaffColors.textBody)),
            ),
        ]),
    ]);
  }

  Future<void> _edit(LoadDetail d, LoadLeg l) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => StaffAddLoadView(service: _svc, edit: l, loadNumber: d.load.number, driverName: d.driverName(l))));
    if (saved == true) _load();
  }

  Future<void> _reason(String title, String hint, Future<String> Function(String) op, {bool required = true}) async {
    final why = await _ask(title, hint);
    if (why == null || (required && why.isEmpty)) return;
    _run(() => op(why));
  }

  Future<void> _problem(LoadLeg l) async {
    const kinds = {'delay': 'Delay', 'breakdown': 'Breakdown', 'detention': 'Detention', 'lumper': 'Lumper', 'rejected': 'Load rejected', 'shortage': 'Shortage', 'damage': 'Damage', 'other': 'Other'};
    var kind = 'delay';
    final note = TextEditingController();
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(builder: (dc, set) {
        return AlertDialog(
          title: const Text('Add problem'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(initialValue: kind, decoration: const InputDecoration(labelText: 'Kind'), items: [for (final e in kinds.entries) DropdownMenuItem(value: e.key, child: Text(e.value))], onChanged: (v) => set(() => kind = v ?? kind)),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'What happened')),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount \$ (optional)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Back')),
            FilledButton(
              onPressed: () {
                Navigator.pop(dc);
                _run(() => _svc.addProblem(l.id, kind: kind, note: note.text.trim(), amount: double.tryParse(amount.text.trim())));
              },
              child: const Text('Add problem'),
            ),
          ],
        );
      }),
    );
  }

  Widget _fact(String label, String value, {bool warn = false}) => SizedBox(
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: AppText.labelSm.copyWith(color: StaffColors.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w700, color: warn ? StaffColors.warning : StaffColors.textStrong)),
        ]),
      );

  Widget _chip(String text, {Color color = StaffColors.textBody, IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)], Text(text, style: AppText.labelMd.copyWith(color: color))]),
      );

  Widget _legCard(LoadDetail d, LoadLeg l) {
    final closed = l.isDone || l.status == 'cancelled';
    final primary = <Widget>[];
    final secondary = <Widget>[];
    Widget fill(String key, String label, VoidCallback f) => FilledButton(key: Key(key), onPressed: _busy ? null : f, child: Text(label));
    Widget outline(String key, String label, VoidCallback f, {Color? color}) => OutlinedButton(
          key: Key(key),
          style: color == null ? null : OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.5))),
          onPressed: _busy ? null : f,
          child: Text(label),
        );
    if (l.status == 'scheduled' && l.driverProfileId == null) primary.add(fill('assign_${l.id}', 'Assign driver', () => _assign(l)));
    if (l.status == 'scheduled' && l.driverProfileId != null) primary.add(fill('send_${l.id}', 'Send to driver', () => _run(() => _svc.sendLeg(l.id))));
    if (l.status == 'offered') primary.add(fill('release_${l.id}', 'Confirm & send', () => _run(() => _svc.releaseLeg(widget.loadId, l.id))));
    if (l.isDelivered) primary.add(fill('complete_${l.id}', 'Mark completed', () => _complete(l)));
    if (!closed) secondary.add(outline('edit_${l.id}', 'Edit', () => _edit(d, l)));
    if (!closed && l.status != 'scheduled' && l.status != 'offered') secondary.add(outline('problem_${l.id}', 'Add problem', () => _problem(l)));
    if (['planned', 'accepted', 'started', 'rolling', 'ended', 'paperwork'].contains(l.status)) secondary.add(outline('hold_${l.id}', 'Hold', () => _reason('Put the trip on hold', 'Why?', (w) => _svc.tripAction(l.id, 'hold', note: w))));
    if (l.status == 'on_hold') secondary.add(outline('resume_${l.id}', 'Resume', () => _run(() => _svc.tripAction(l.id, 'resume'))));
    if (l.onDriver) secondary.add(outline('end_${l.id}', 'End load', () => _end(l), color: StaffColors.warning));
    if (l.startedAt != null || l.endedAt != null) secondary.add(outline('times_${l.id}', 'Correct times', () => _correctTimes(l)));
    if (l.startedAt != null || l.endedAt != null || l.totalMileage != null) secondary.add(outline('miles_${l.id}', 'Miles', () => _miles(l)));
    if (l.endedAt != null && l.milesSource != 'manual') secondary.add(outline('recheck_${l.id}', 'Re-check miles', () => _run(() => _svc.matchGps(widget.loadId, l.id))));
    if (!closed) secondary.add(outline('cancel_${l.id}', 'Cancel trip', () => _reason('Cancel this trip', 'Reason (the driver sees it)', (w) => _svc.tripAction(l.id, 'cancel', note: w)), color: StaffColors.danger));
    final live = const ['planned', 'accepted', 'started', 'rolling', 'on_hold'].contains(l.status);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _card([
        Row(children: [
          Expanded(child: Text('Leg ${l.legNo} · #${l.tripNo ?? ''}', style: AppText.titleMd.copyWith(color: StaffColors.textStrong))),
          StaffPill(label: l.isLate ? 'Late · ${l.statusLabel}' : l.statusLabel, color: l.isLate ? StaffColors.danger : legStatusColor(l.status)),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.sm)),
          child: Wrap(spacing: 16, runSpacing: 12, children: [
            _fact('Driver', '${d.driverName(l)}${l.isTeam ? ' + team' : ''}'),
            _fact('Truck', l.truck ?? '—'),
            _fact('Trailer', l.trailers ?? '—'),
            _fact('Load #', d.load.number),
            if (l.temperature != null) _fact('Temperature', l.temperature!),
            if (l.totalMileage != null) _fact('Miles', '${fmtMiles(l.totalMileage)} · ${l.milesSourceLabel}') else if (l.endedAt != null) _fact('Miles', l.milesNote ?? 'Missing', warn: true),
            if (l.loadedTrailer) _fact('Trailer', 'Loaded'),
          ]),
        ),
        if (l.handoverReason != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.handoverReason!, style: AppText.bodySm.copyWith(color: StaffColors.textMuted))),
        if (l.needsReview)
          Container(
            key: Key('review_${l.id}'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: StaffColors.warning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadii.sm), border: Border.all(color: StaffColors.warning.withValues(alpha: 0.5))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: StaffColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Check this load before the driver relies on it:', style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                  for (final n in (l.reviewNotes ?? '').split('\n').where((x) => x.trim().isNotEmpty)) Text('• $n', style: AppText.bodyMd),
                ]),
              ),
            ]),
          ),
        if (primary.isNotEmpty || secondary.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (primary.isNotEmpty) SizedBox(width: double.infinity, child: Wrap(spacing: 8, runSpacing: 8, children: primary)),
          if (secondary.isNotEmpty) Padding(padding: EdgeInsets.only(top: primary.isEmpty ? 0 : 8), child: Wrap(spacing: 8, runSpacing: 8, children: secondary)),
        ],
      ]),
      if (live) LivePanel(tripId: l.id, service: _svc),
      _card([
        Text('Stops', style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
        const SizedBox(height: 8),
        for (var i = 0; i < l.stops.length; i++) _stopTile(l.stops[i], i),
      ]),
    ]);
  }

  Widget _stopTile(LoadStop s, int i) {
    final c = s.departedAt != null ? StaffColors.success : s.arrivedAt != null ? StaffColors.warning : StaffColors.hairline;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.sm), border: Border(left: BorderSide(color: c, width: 4), top: const BorderSide(color: StaffColors.hairline), right: const BorderSide(color: StaffColors.hairline), bottom: const BorderSide(color: StaffColors.hairline))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 13, backgroundColor: StaffColors.canvas, child: Text('${i + 1}', style: AppText.labelMd.copyWith(fontWeight: FontWeight.w800, color: StaffColors.textStrong))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.typeLabel} · ${s.title}', style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
            if (s.address.isNotEmpty) Text(s.address, style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _chip('Appointment ${s.appointmentLocal == null ? '—' : fmtLocal(s.appointmentLocal)}', icon: Icons.event_rounded),
              _chip('Arrived ${s.arrivedAt == null ? '—' : fmtDateTime(s.arrivedAt)}', color: s.arrivedAt == null ? StaffColors.textMuted : StaffColors.warning),
              _chip('Left ${s.departedAt == null ? '—' : fmtDateTime(s.departedAt)}', color: s.departedAt == null ? StaffColors.textMuted : StaffColors.success),
            ]),
          ]),
        ),
      ]),
    );
  }
}
