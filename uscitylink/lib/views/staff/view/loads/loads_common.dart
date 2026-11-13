import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Website that hosts the public /track/<token> page, e.g. 'https://dispatch.example.com'.
/// Empty: Share sends the load number for the app's "Track a load" instead of a link.
const String kTrackingWebsite = '';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  return '${_months[l.month - 1]} ${l.day}, $h:${l.minute.toString().padLeft(2, '0')} ${l.hour >= 12 ? 'PM' : 'AM'}';
}

String fmtDay(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${_months[l.month - 1]} ${l.day}, ${l.year}';
}

/// "2026-11-12T08:00" (the stop's own local time) → "Nov 12, 8:00 AM"
String fmtLocal(String? s) {
  final d = s == null ? null : DateTime.tryParse(s);
  if (d == null) return '';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${_months[d.month - 1]} ${d.day}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String fmtMiles(double? m) => m == null ? '—' : '${m == m.roundToDouble() ? m.toInt() : m.toStringAsFixed(1)} mi';

String fmtMinutes(int? m) {
  if (m == null) return '—';
  if (m < 60) return '$m min';
  return '${m ~/ 60}h ${m % 60}m';
}

Color loadStatusColor(String s) => switch (s) {
      'transfer' => StaffColors.orange,
      'waiting' => StaffColors.danger,
      'scheduled' => StaffColors.textMuted,
      'active' => StaffColors.sky,
      'delivered' => StaffColors.teal,
      'completed' => StaffColors.success,
      _ => StaffColors.textMuted,
    };

Color legStatusColor(String s) => switch (s) {
      'offered' => StaffColors.danger,
      'scheduled' => StaffColors.textMuted,
      'planned' || 'accepted' || 'started' || 'rolling' => StaffColors.sky,
      'ended' || 'paperwork' => StaffColors.teal,
      'completed' || 'routed' => StaffColors.success,
      'on_hold' => StaffColors.warning,
      _ => StaffColors.textMuted,
    };

class LoadCard extends StatelessWidget {
  const LoadCard({super.key, required this.load, required this.names, this.onTap});
  final StaffLoad load;
  final Map<String, String> names;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final legs = load.activeLegs;
    final first = legs.isEmpty ? null : legs.first.first;
    final last = legs.isEmpty ? null : legs.last.last;
    final pickupAt = first?.appointmentLocal;
    final dropAt = last?.appointmentLocal;
    final meta = [load.typeLabel, if (legs.length > 1) '${legs.length} legs', if (load.createdAt != null) 'Added ${fmtDay(load.createdAt)}'].join('  ·  ');
    return Material(
      color: StaffColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        key: Key('load_${load.id}'),
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: StaffColors.hairline)),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Load # + status
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: loadStatusColor(load.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_shipping_rounded, size: 19, color: loadStatusColor(load.status)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Load ${load.number}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.titleMd.copyWith(color: StaffColors.textStrong, fontWeight: FontWeight.w800)),
                  Text(meta, key: const Key('loadMeta'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
                ]),
              ),
              StaffPill(label: load.statusLabel, color: loadStatusColor(load.status)),
            ]),
            if (first != null) ...[
              const SizedBox(height: 12),
              _RoutePoint(color: StaffColors.success, label: 'PICKUP', stop: first, when: pickupAt, line: last != null && last != first),
              if (last != null && last != first) _RoutePoint(color: StaffColors.danger, label: 'DELIVERY', stop: last, when: dropAt, line: false),
            ],
            if (legs.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: StaffColors.hairline)),
              for (final l in legs)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Row(children: [
                    StaffAvatar(name: l.driverProfileId == null ? '?' : (names[l.driverProfileId] ?? 'Driver'), size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          if (legs.length > 1) TextSpan(text: 'Leg ${l.legNo}  ', style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
                          TextSpan(text: l.driverProfileId == null ? 'No driver yet' : _title(names[l.driverProfileId] ?? 'Driver'), style: AppText.bodySm.copyWith(color: StaffColors.textStrong, fontWeight: FontWeight.w600)),
                          if (l.truck != null) TextSpan(text: '  ·  Truck ${l.truck}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: legStatusColor(l.status), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(l.statusLabel, style: AppText.labelMd.copyWith(color: legStatusColor(l.status), fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// "TAKDEER SINGH" → "Takdeer Singh"
String _title(String s) => s.split(' ').map((w) => w.isEmpty ? w : (w == w.toUpperCase() && w.length > 1 ? w[0] + w.substring(1).toLowerCase() : w)).join(' ');

/// One end of the route: coloured dot (with the line down to the next), city, place name and time.
class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.color, required this.label, required this.stop, this.when, required this.line});
  final Color color;
  final String label;
  final LoadStop stop;
  final String? when;
  final bool line;

  @override
  Widget build(BuildContext context) {
    final place = stop.place.isEmpty ? stop.title : stop.place;
    final name = stop.name != null && stop.name != place ? stop.name! : null;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 16,
          child: Column(children: [
            const SizedBox(height: 4),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.25), width: 3))),
            if (line) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: StaffColors.hairline)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: line ? 10 : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: AppText.labelSm.copyWith(color: StaffColors.textMuted, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                if (when != null && when!.isNotEmpty) ...[
                  const Spacer(),
                  Icon(Icons.schedule_rounded, size: 12, color: StaffColors.textMuted),
                  const SizedBox(width: 3),
                  Text(fmtLocal(when), style: AppText.labelMd.copyWith(color: StaffColors.textBody)),
                ],
              ]),
              Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyMd.copyWith(color: StaffColors.textStrong, fontWeight: FontWeight.w700)),
              if (name != null) Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String body, String yes = 'Yes', String no = 'Cancel'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(no)), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(yes))],
    ),
  );
  return r == true;
}

void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? StaffColors.danger : null));
}

String errText(Object e) => e.toString().replaceFirst('Exception: ', '');

/// "Load 1011 is already lined up": dispatch saved this Load # earlier (not sent). Sending / saving it
/// again replaces that copy. When the driver is on another load now, the same question offers End
/// current & send, or line it up after. Returns replace | line | end, or null (cancel).
Future<String?> askReplaceLinedUp(BuildContext context, {required String loadNo, required LegBrief linedUp, LegBrief? current, required bool send}) {
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      key: const Key('replaceLinedUpDialog'),
      icon: const Icon(Icons.playlist_add_check_rounded, color: StaffColors.sky, size: 32),
      title: Text('Load $loadNo is already lined up'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.sm), border: Border.all(color: StaffColors.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LINED UP · NOT SENT YET', style: AppText.labelSm.copyWith(color: StaffColors.textMuted, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('#${linedUp.tripNo ?? ''} · ${linedUp.driverName ?? 'No driver'}${linedUp.truck == null ? '' : ' · Truck ${linedUp.truck}'}', style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w700)),
            Text('${linedUp.from} → ${linedUp.to}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 12),
        Text('${send ? 'Sending' : 'Saving'} this load replaces that copy — it comes off the lineup (kept in the load\'s history) and this one takes its place with the same number.', style: AppText.bodyMd),
        if (current != null) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('replaceDriverBusy'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: StaffColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Text(
              '${current.driverName ?? 'The driver'} is on load #${current.tripNo ?? ''} now (${current.from} → ${current.to}, ${current.statusLabel.toLowerCase()}). End it and send this one, or line this one up after it?',
              style: AppText.bodySm.copyWith(color: StaffColors.textStrong),
            ),
          ),
        ],
      ]),
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        if (!send)
          FilledButton(key: const Key('answerReplace'), onPressed: () => Navigator.pop(d, 'replace'), child: const Text('Replace lined-up copy'))
        else if (current != null) ...[
          OutlinedButton(key: const Key('answerReplaceLineUp'), onPressed: () => Navigator.pop(d, 'line'), child: Text('Replace & line up after #${current.tripNo ?? ''}')),
          FilledButton(
            key: const Key('answerReplaceEndCurrent'),
            style: FilledButton.styleFrom(backgroundColor: StaffColors.warning),
            onPressed: () => Navigator.pop(d, 'end'),
            child: Text('End #${current.tripNo ?? ''} & send'),
          ),
        ] else
          FilledButton(key: const Key('answerReplaceSend'), onPressed: () => Navigator.pop(d, 'replace'), child: const Text('Replace & send now')),
      ],
    ),
  );
}
