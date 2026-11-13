import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

String _hours(num? minutes) {
  if (minutes == null) return '—';
  final m = minutes.round();
  return m >= 60 ? '${m ~/ 60} h ${m % 60} min' : '$m min';
}

String _ago(DateTime? at) {
  if (at == null) return '';
  final m = DateTime.now().difference(at).inMinutes;
  return m < 1 ? 'just now' : m < 60 ? '$m min ago' : '${m ~/ 60} h ago';
}

/// Live tracking of a leg on the road: the truck now (Samsara), fuel, miles left, final ETA and how the
/// ETA is worked out (US hours-of-service: breaks, fuel stops, rests) — same as the web trip panel.
class LivePanel extends StatefulWidget {
  const LivePanel({super.key, required this.tripId, required this.service});
  final int tripId;
  final LoadsService service;

  @override
  State<LivePanel> createState() => _LivePanelState();
}

class _LivePanelState extends State<LivePanel> {
  LiveTrip? _live;
  String? _error;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _fetch();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final l = await widget.service.live(widget.tripId);
      if (mounted) setState(() => (_live = l, _error = null, _loading = false));
    } catch (e) {
      if (mounted) setState(() => (_error = errText(e), _loading = false));
    }
  }

  (String, String) _truckState(LiveTrip l) {
    final t = l.truck;
    if (t == null) return ('No position', l.truckProblem ?? '');
    final moving = (t.speedMph ?? 0) > 3;
    final stopped = !moving && t.stoppedSince != null ? ' · ${_hours(DateTime.now().difference(t.stoppedSince!).inMinutes)}' : '';
    final v = moving ? 'Moving · ${t.speedMph!.round()} mph' : (t.engine == 'Idle' || t.engine == 'On') ? 'Stopped$stopped · engine on' : 'Parked$stopped · engine off';
    return (v, t.address ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l = _live;
    return Container(
      key: const Key('livePanel'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: StaffColors.card, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: StaffColors.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.my_location_rounded, size: 18, color: StaffColors.sky),
          const SizedBox(width: 6),
          Expanded(child: Text('Live tracking', style: AppText.titleMd.copyWith(color: StaffColors.textStrong))),
          if (l?.truck != null) Text('Samsara · ${_ago(l!.truck!.at)}', style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
          IconButton(visualDensity: VisualDensity.compact, onPressed: _fetch, icon: const Icon(Icons.refresh_rounded, size: 20)),
        ]),
        if (_loading && l == null) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        if (_error != null && l == null) Text('Live tracking isn\'t available right now.', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
        if (l != null) ..._content(l),
      ]),
    );
  }

  List<Widget> _content(LiveTrip l) {
    final t = l.truck;
    final stale = t?.at != null && DateTime.now().difference(t!.at!).inMinutes > 30;
    final (state, caption) = _truckState(l);
    final fuel = t?.fuelPercent;
    return [
      if (stale) _note('Samsara last saw truck ${t.vehicleName ?? ''} ${_ago(t.at)} — position and ETAs may be out of date.', StaffColors.warning),
      if (t == null && l.truckProblem != null) _note(l.truckProblem!, StaffColors.sky),
      if (l.routeProblem != null) _note(l.routeProblem!, StaffColors.warning),
      const SizedBox(height: 4),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        Widget tile(IconData i, String label, String value, {String? cap, Widget? extra}) => SizedBox(width: w, child: _StatTile(icon: i, label: label, value: value, caption: cap, extra: extra));
        return Wrap(spacing: 10, runSpacing: 10, children: [
          tile(Icons.speed_rounded, 'Truck', state, cap: caption),
          tile(Icons.local_gas_station_rounded, 'Fuel', fuel == null ? '—' : '${fuel.round()}%',
              cap: l.fuelGallons == null ? null : '~${l.fuelGallons!.round()} gal diesel to finish',
              extra: fuel == null ? null : Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (fuel / 100).clamp(0, 1), minHeight: 6, color: fuel < 20 ? StaffColors.danger : fuel < 40 ? StaffColors.warning : StaffColors.success, backgroundColor: StaffColors.hairline)))),
          tile(Icons.route_rounded, 'Remaining', l.miles == null ? '—' : '${l.miles!.round()} mi', cap: l.driveMinutes == null ? null : '${_hours(l.driveMinutes)} driving (truck pace)'),
          tile(Icons.schedule_rounded, 'Final ETA', l.eta == null ? '—' : fmtDateTime(l.eta), cap: l.eta == null ? null : 'Includes ${_hours(l.restMinutes ?? 0)} of stops (breaks, rest, fuel)'),
        ]);
      }),
      if (l.plan != null) _plan(l.plan!, l.team),
      if (l.stops.isNotEmpty) ...[
        const SizedBox(height: 12),
        for (final s in l.stops)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.type == 'pickup' ? 'Pickup' : 'Delivery'} · ${s.name ?? s.place}', style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                  Text('${s.place} · ${s.miles.round()} mi · ${_hours(s.driveMinutes)} drive · ETA ${fmtDateTime(s.eta)}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                ]),
              ),
              if (s.lateMinutes != null) StaffPill(label: s.lateMinutes! > 0 ? '${_hours(s.lateMinutes)} late' : '${_hours(-s.lateMinutes!)} early', color: s.lateMinutes! > 0 ? StaffColors.danger : StaffColors.success),
            ]),
          ),
      ],
    ];
  }

  Widget _note(String text, Color color) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.sm)),
        child: Text(text, style: AppText.bodySm.copyWith(color: StaffColors.textStrong)),
      );

  Widget _plan(EtaPlan p, bool team) {
    Widget chip(String big, String small) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: StaffColors.hairline.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
          child: Text.rich(TextSpan(children: [TextSpan(text: big, style: const TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: '  $small', style: TextStyle(color: StaffColors.textMuted, fontSize: 12))])),
        );
    return Container(
      key: const Key('etaPlan'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('How the ETA is worked out', style: AppText.titleMd.copyWith(fontSize: 14))),
          StaffPill(label: team ? 'Team · fuel stops only' : 'Solo · US hours of service', color: StaffColors.primary),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          chip(_hours(p.drivingMinutes), 'driving'),
          if (p.breakMinutes > 0) chip(_hours(p.breakMinutes), '${p.breaks} × 30 min breaks'),
          if (p.fuelMinutes > 0) chip(_hours(p.fuelMinutes), '${p.fuels} × 1 h fuel stops'),
          if (p.restMinutes > 0) chip(_hours(p.restMinutes), '${p.rests} × 10 h rests'),
        ]),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: StaffColors.primary, borderRadius: BorderRadius.circular(10)), child: Text('${_hours(p.totalMinutes)} total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(height: 8),
        Text('Google says ${_hours(p.googleMinutes)} for a car; a loaded truck averages 60 mph at most. Rules: 30 min break after 8 h driving · 10 h rest after 11 h driving or 14 h on duty · 1 h fuel every 1,000 mi.', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, this.caption, this.extra});
  final IconData icon;
  final String label, value;
  final String? caption;
  final Widget? extra;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 16, color: StaffColors.textMuted), const SizedBox(width: 6), Text(label, style: AppText.labelMd.copyWith(color: StaffColors.textMuted))]),
          const SizedBox(height: 4),
          Text(value, style: AppText.titleMd.copyWith(color: StaffColors.textStrong, height: 1.25)),
          if (extra != null) extra!,
          if (caption != null && caption!.isNotEmpty) Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
        ]),
      );
}
