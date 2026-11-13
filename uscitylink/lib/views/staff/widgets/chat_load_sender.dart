import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';
import 'package:uscitylink/utils/load_text.dart';
import 'package:uscitylink/views/staff/view/loads/loads_common.dart';

/// A load pasted in a driver's chat box (with its Load #) is sent as a load, never as a chat message:
/// the driver gets the standard load message only when it's really sent; lined up → nothing yet.
/// The same questions as Add load are asked first. Returns true when it was sent or lined up (clear
/// the input), false when dispatch cancelled or it failed (keep the text).
class ChatLoadSender {
  static LoadsService service = LoadsService();

  static bool isLoad(String text) => looksLikeLoad(text) && loadNoIn(text) != null;

  static Future<bool> send(BuildContext context, String text, String driverProfileId) async {
    final loadNo = loadNoIn(text) ?? '';
    var endPrevious = false, endCurrent = false, lineUp = false, replace = false;
    for (var i = 0; i < 4; i++) {
      try {
        final msg = await service.sendLoadText(text, driverProfileId, endPrevious: endPrevious, endDriverCurrent: endCurrent, lineUp: lineUp, replace: replace);
        _toast(msg);
        return true;
      } on NeedsAnswer catch (n) {
        if (!context.mounted) return false;
        if (n.needs == 'replaceLinedUp' && n.linedUp != null) {
          final c = await askReplaceLinedUp(context, loadNo: loadNo, linedUp: n.linedUp!, current: n.current, send: true);
          if (c == null) return false;
          replace = true;
          if (c == 'line') lineUp = true;
          if (c == 'end') endCurrent = true;
        } else if (n.needs == 'endPrevious') {
          final p = n.prev;
          final ok = await confirmDialog(context,
              title: 'End leg ${p?.legNo ?? ''} first?',
              body: '${p?.driverName ?? 'The driver'} hasn\'t ended leg ${p?.legNo ?? ''} of load $loadNo (${p?.from ?? ''} → ${p?.to ?? ''}). End it now and send this leg?',
              yes: 'End leg ${p?.legNo ?? ''} & send');
          if (!ok) return false;
          endPrevious = true;
        } else {
          final c = n.current;
          final choice = await showDialog<String>(
            context: context,
            builder: (d) => AlertDialog(
              key: const Key('chatLoadDriverBusy'),
              title: Text('${c?.driverName ?? 'The driver'} is on another load'),
              content: Text(
                  'Load #${c?.tripNo ?? ''} (${c?.from ?? ''} → ${c?.to ?? ''}, ${c?.statusLabel.toLowerCase() ?? ''}).\n\nEnd it now and send load $loadNo, or line $loadNo up to go out by itself when #${c?.tripNo ?? ''} is delivered? Lined up, the driver doesn\'t see it yet.'),
              actionsOverflowDirection: VerticalDirection.up,
              actionsOverflowButtonSpacing: 8,
              actions: [
                TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                OutlinedButton(key: const Key('chatLoadLineUp'), onPressed: () => Navigator.pop(d, 'line'), child: Text('Line up after #${c?.tripNo ?? ''}')),
                FilledButton(key: const Key('chatLoadEndCurrent'), onPressed: () => Navigator.pop(d, 'end'), child: Text('End #${c?.tripNo ?? ''} & send')),
              ],
            ),
          );
          if (choice == null) return false;
          if (choice == 'line') lineUp = true;
          if (choice == 'end') endCurrent = true;
        }
      } catch (e) {
        _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
        return false;
      }
    }
    return false;
  }

  static void _toast(String text, {bool error = false}) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(error ? 'Load not sent' : 'Load', text,
        backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF0B5D53), colorText: Colors.white, duration: Duration(seconds: error ? 8 : 4), snackPosition: SnackPosition.TOP);
  }
}
