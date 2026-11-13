import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';
import 'package:uscitylink/views/staff/widgets/repair_load.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Missed loads: chat messages from the last 14 days that look like loads but are not in Loads (Add), and
/// loads made from a chat message that don't match it (Repair — e.g. the one address was guessed as a
/// pickup, or the assistant's old "TRIP #…" message). Each opens the same confirm dialog as the message
/// menu; nothing is sent to the driver.
class StaffMissedLoadsView extends StatefulWidget {
  const StaffMissedLoadsView({super.key, this.service});
  final LoadsService? service;

  @override
  State<StaffMissedLoadsView> createState() => _StaffMissedLoadsViewState();
}

class _StaffMissedLoadsViewState extends State<StaffMissedLoadsView> {
  late final LoadsService _svc = widget.service ?? LoadsService();
  List<MissedLoad>? _list;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final l = await _svc.missedLoads();
      if (mounted) setState(() => _list = l);
    } catch (e) {
      if (mounted) setState(() => _error = errText(e));
    }
  }

  Future<void> _open(MissedLoad l) async {
    final done = await RepairLoad.show(context, l.messageId);
    if (done) _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      backgroundColor: StaffColors.canvas,
      body: Column(children: [
        StaffHeader(
          title: 'Missed loads',
          subtitle: 'Last 14 days · nothing is sent to the driver',
          leadingIcon: Icons.arrow_back_rounded,
          onLeading: () => Navigator.pop(context),
          actions: [StaffGlassButton(icon: Icons.refresh_rounded, onTap: _load)],
        ),
        Expanded(
          child: _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: AppText.bodyMd.copyWith(color: StaffColors.danger))))
              : list == null
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? Center(child: Text('Nothing missed — every load message is in Loads.', key: const Key('missedEmpty'), style: AppText.bodyMd.copyWith(color: StaffColors.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _row(list[i]),
                        ),
        ),
      ]),
    );
  }

  Widget _row(MissedLoad l) => Container(
        key: Key('missed_${l.messageId}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: StaffColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: StaffColors.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StaffPill(label: l.missing ? 'Not in Loads' : 'Fix details', color: l.missing ? StaffColors.warning : StaffColors.sky),
            const SizedBox(width: 8),
            Expanded(child: Text(l.loadNo != null ? 'Load ${l.loadNo}' : 'No Load # in the text', style: AppText.labelMd, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Text('${l.driverName ?? 'Driver'} · ${fmtDateTime(l.at)}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
          const SizedBox(height: 4),
          if (l.missing)
            Text(l.firstLine, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySm.copyWith(color: StaffColors.textBody))
          else
            for (final c in l.changes) Text(c, style: AppText.bodySm.copyWith(color: StaffColors.textBody)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(key: Key('missedOpen_${l.messageId}'), onPressed: () => _open(l), child: Text(l.missing ? 'Add to loads' : 'Repair')),
          ),
        ]),
      );
}
