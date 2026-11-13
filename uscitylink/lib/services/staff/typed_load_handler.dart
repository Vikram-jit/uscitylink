import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';

/// A load typed / pasted into a driver's chat is handled like Add load → Send now. The server tells the
/// sender what happened (socket "load:typed"): sent, no Load # in the text, or a question to answer.
class TypedLoadHandler {
  static LoadsService service = LoadsService();
  static bool _open = false;

  static void handle(dynamic raw) {
    if (raw is! Map) return;
    final d = Map<String, dynamic>.from(raw);
    final who = '${d['driverName'] ?? 'the driver'}';
    switch ('${d['kind']}') {
      case 'sent':
        final leg = (d['legNo'] as num?)?.toInt() ?? 1;
        _toast('Load sent', 'Load ${d['loadNo']}${leg > 1 ? ' (leg $leg)' : ''} sent to $who — from your message');
      case 'noLoadNo':
        _toast('No Load # in your message', 'The load you typed to $who has no Load # — add a line "LOAD # 1234" and send it again, or use Add load.', warn: true);
      case 'question':
        _ask(d, who);
    }
  }

  static void _toast(String title, String body, {bool warn = false}) {
    Get.snackbar(title, body, backgroundColor: warn ? const Color(0xFFB45309) : const Color(0xFF0B5D53), colorText: Colors.white, duration: Duration(seconds: warn ? 12 : 5), snackPosition: SnackPosition.TOP);
  }

  static Future<void> _ask(Map<String, dynamic> d, String who) async {
    if (_open) return;
    final info = d['info'] is Map ? Map<String, dynamic>.from(d['info']) : <String, dynamic>{};
    LegBrief? leg(dynamic v) => v is Map ? LegBrief.fromJson(Map<String, dynamic>.from(v)) : null;
    final needs = '${d['needs']}';
    final prev = leg(info['prev']), cur = leg(info['current']), lined = leg(info['linedUp']);
    final id = '${d['id']}';
    _open = true;
    try {
      final String? choice;
      if (needs == 'replaceLinedUp' && lined != null && Get.context != null) {
        final c = await askReplaceLinedUp(Get.context!, loadNo: '${d['loadNo']}', linedUp: lined, current: cur, send: true);
        if (c == null) return;
        final res = await service.answerTyped(id, replace: true, lineUp: c == 'line', endDriverCurrent: c == 'end');
        _open = false;
        handle({...res, 'driverName': who});
        return;
      } else if (needs == 'endPrevious' && prev != null) {
        choice = await Get.dialog<String>(AlertDialog(
          title: Text('Load ${d['loadNo']}: end leg ${prev.legNo} first?'),
          content: Text('You sent load ${d['loadNo']} to $who in chat. ${prev.driverName ?? 'The driver'} hasn\'t ended leg ${prev.legNo} (#${prev.tripNo}, ${prev.from} → ${prev.to}) yet. End it now and send this as leg ${prev.legNo + 1}?'),
          actions: [TextButton(onPressed: () => Get.back(), child: const Text('Not now')), FilledButton(onPressed: () => Get.back(result: 'end'), child: Text('End leg ${prev.legNo} & send'))],
        ));
      } else if (needs == 'driverBusy' && cur != null) {
        choice = await Get.dialog<String>(AlertDialog(
          title: Text('${cur.driverName ?? who} is on another load'),
          content: Text('You sent load ${d['loadNo']} in chat, but ${cur.driverName ?? who} has load #${cur.tripNo} (${cur.from} → ${cur.to}, ${cur.statusLabel.toLowerCase()}). End it now and send this one, or line this one up after it?'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Not now')),
            OutlinedButton(onPressed: () => Get.back(result: 'line'), child: Text('Line up after #${cur.tripNo}')),
            FilledButton(onPressed: () => Get.back(result: 'end'), child: Text('End #${cur.tripNo} & send')),
          ],
        ));
      } else {
        return;
      }
      if (choice == null) return;
      final res = await service.answerTyped(id, endPrevious: needs == 'endPrevious' && choice == 'end', endDriverCurrent: needs == 'driverBusy' && choice == 'end', lineUp: choice == 'line');
      _open = false;
      handle({...res, 'driverName': who});
    } catch (e) {
      _toast('Could not send the load', e.toString().replaceFirst('Exception: ', ''), warn: true);
    } finally {
      _open = false;
    }
  }
}
