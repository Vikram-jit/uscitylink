import 'package:flutter/material.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/load_text.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';

/// Add to loads / Repair on a chat message. The server re-reads the message with today's rules and says
/// what it would do; nothing changes until dispatch confirms here.
///  * add: the message never became a load → it is ADDED to Loads (lined up). Nothing is sent to the
///    driver. A text with no address becomes a plan (stops added later).
///  * repair: a load exists but differs from the message (e.g. the one address was guessed as a pickup) →
///    shows before → after, then fixes the load and replaces the assistant's old message text.
///  * ok: the load already matches.
class RepairLoad {
  static LoadsService service = LoadsService();

  /// A load-looking text from dispatch, or the assistant's own load message ("TRIP #…" / "LOAD #…").
  static bool canRepair(String? body, {String? url, bool? automated}) {
    if (url != null && url.isNotEmpty) return false;
    final text = body ?? '';
    if (automated == true) return RegExp(r'^\s*(?:TRIP|LOAD)\b', caseSensitive: false).hasMatch(text);
    return looksLikeLoad(text);
  }

  /// Returns true when something was added / repaired (so the caller can refresh).
  static Future<bool> show(BuildContext context, String messageId) async {
    RepairPreview pv;
    try {
      pv = await service.repairPreview(messageId);
    } catch (e) {
      if (context.mounted) snack(context, errText(e), error: true);
      return false;
    }
    if (!context.mounted) return false;
    final loadNo = TextEditingController(text: pv.mode == 'add' ? (pv.loadNo ?? loadNoIn(pv.text) ?? '') : '');
    final go = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(builder: (dc, set) {
        final adding = pv.mode == 'add';
        final okLoadNo = !adding || loadNo.text.trim().isNotEmpty;
        return AlertDialog(
          key: const Key('repairLoadDialog'),
          title: Text(adding ? 'Add this message to Loads' : pv.mode == 'repair' ? 'Repair this load' : 'Nothing to repair'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (adding) ...[
                _box(pv.text, dim: true),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('repairLoadNo'),
                  controller: loadNo,
                  onChanged: (_) => set(() {}),
                  decoration: InputDecoration(labelText: 'Load #', errorText: okLoadNo ? null : 'No Load # in the message — type it'),
                ),
                if (pv.plan) ...[
                  const SizedBox(height: 10),
                  _note('No address found in this message — it is added as a plan (Load # only). Add the stops from Loads before sending it.', const Color(0xFFB45309)),
                ],
                const SizedBox(height: 10),
                _note("Added to Loads as saved for later — nothing is sent to the driver. A single address with no pickup / drop label is the drop.", const Color(0xFF1D4ED8)),
              ] else if (pv.mode == 'ok')
                Text('Load ${pv.load?.loadNo ?? ''} already matches this message.', key: const Key('repairNothing'))
              else ...[
                Text('Load ${pv.load?.loadNo ?? ''}${pv.load != null && !pv.load!.onlyLeg ? ' · leg ${pv.load!.legNo}' : ''} · ${pv.load?.driverName ?? 'No driver'}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (pv.changes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('LOAD DETAILS THAT WILL CHANGE', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  for (final c in pv.changes)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${c.label}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: c.before, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Color(0xFF64748B))),
                        const TextSpan(text: '  →  '),
                        TextSpan(text: c.after, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                      ])),
                    ),
                ],
                if (pv.messageAfter != null) ...[
                  const SizedBox(height: 12),
                  const Text("THE ASSISTANT'S MESSAGE IN THE CHAT WILL BE REPLACED", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  _box(pv.messageBefore ?? '', dim: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('↓')),
                  _box(pv.messageAfter!),
                ],
                if (!pv.canApply && pv.why != null) ...[
                  const SizedBox(height: 10),
                  _note(pv.why!, const Color(0xFFB45309)),
                ],
                const SizedBox(height: 10),
                _note("Dispatch's own typed text is never rewritten. The driver sees the new message text when their chat reloads.", const Color(0xFF1D4ED8)),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc, false), child: Text(pv.mode == 'ok' ? 'Close' : 'Cancel')),
            if (pv.mode != 'ok')
              FilledButton(
                key: const Key('repairSubmit'),
                onPressed: (pv.canApply && okLoadNo) ? () => Navigator.pop(dc, true) : null,
                child: Text(adding ? 'Add to loads' : 'Replace & update'),
              ),
          ],
        );
      }),
    );
    if (go != true) return false;
    try {
      final msg = await service.repairApply(messageId, loadNo: pv.mode == 'add' ? loadNo.text : null);
      if (context.mounted) snack(context, msg);
      return true;
    } catch (e) {
      if (context.mounted) snack(context, errText(e), error: true);
      return false;
    }
  }

  static Widget _box(String text, {bool dim = false}) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 130),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(child: Text(text, style: TextStyle(fontSize: 12, color: dim ? const Color(0xFF475569) : const Color(0xFF0F172A)))),
      );

  static Widget _note(String text, Color color) => Text(text, style: TextStyle(fontSize: 12.5, color: color));
}
