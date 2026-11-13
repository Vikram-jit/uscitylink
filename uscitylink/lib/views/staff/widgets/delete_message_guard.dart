import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/model/staff/load_models.dart';
import 'package:uscitylink/services/staff/loads_service.dart';

/// Deleting a chat message that made a load (the load message, or a load typed in the chat): dispatch
/// chooses — delete the load too, keep it, or cancel. A message with no load is deleted straight away.
class DeleteMessageGuard {
  static LoadsService service = LoadsService();

  static Future<void> delete(BuildContext context, String messageId, void Function(String id) deleteMessage) async {
    List<MessageLoad>? loads;
    try {
      loads = await service.loadsOfMessage(messageId);
    } catch (_) {
      loads = null; // can't tell: ask plainly below rather than lose a load silently
    }
    if (loads != null && loads.isEmpty) {
      deleteMessage(messageId);
      return;
    }
    if (!context.mounted) return;
    final found = loads ?? const <MessageLoad>[];
    final deletable = found.where((l) => l.canDelete).toList();
    final partLeg = deletable.any((l) => !l.onlyLeg);
    final choice = await showDialog<String>(
      context: context,
      builder: (dc) => AlertDialog(
        key: const Key('deleteMessageDialog'),
        title: Text(found.isEmpty ? 'Delete message?' : 'This message made a load'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (found.isEmpty) const Text("Couldn't check for a load on this message. Delete the message only?"),
          for (final l in found)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${l.driverName ?? 'No driver'} · ${l.status}', style: const TextStyle(color: Color(0xFF64748B))),
                if (!l.canDelete && l.why != null) Text(l.why!, style: const TextStyle(color: Color(0xFFB45309), fontSize: 12)),
              ]),
            ),
          if (deletable.isNotEmpty)
            Text("Delete the ${partLeg ? 'leg' : 'load'} too? It's removed from Loads and from the driver's app, with its history. This can't be undone.",
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dc), child: const Text('Cancel')),
          TextButton(key: const Key('deleteMessageOnly'), onPressed: () => Navigator.pop(dc, 'message'), child: Text(found.isEmpty ? 'Delete message' : 'Message only')),
          if (deletable.isNotEmpty)
            FilledButton(
              key: const Key('deleteMessageAndLoad'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(dc, 'load'),
              child: Text(partLeg ? 'Delete with leg' : 'Delete with load'),
            ),
        ],
      ),
    );
    if (choice == 'message') {
      deleteMessage(messageId);
    } else if (choice == 'load') {
      try {
        for (final l in deletable) {
          await service.deleteLoadOfMessage(messageId, l.legId);
        }
        deleteMessage(messageId);
        Get.snackbar('Deleted', deletable.length == 1 ? '${deletable.first.title} deleted with the message' : 'Loads deleted with the message', snackPosition: SnackPosition.BOTTOM);
      } catch (e) {
        Get.snackbar('Not deleted', '$e'.replaceFirst('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}
