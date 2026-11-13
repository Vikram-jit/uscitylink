import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/utils/load_text.dart';

/// Staff chat boxes: a message that looks like a load (PICKUP / DELIVERY headings or appointment
/// times) must have its LOAD # line before it can be sent. Returns true when sending is blocked;
/// the dialog can put a "LOAD # " line at the top and the cursor right after it.
bool blockLoadWithoutNo(TextEditingController input) {
  final text = input.text;
  if (!loadMissingNo(text)) return false;
  Get.dialog(
    AlertDialog(
      key: const Key('loadNoMissingDialog'),
      icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
      title: const Text('Load # missing — not sent'),
      content: const Text('This message has an address and pickup / delivery / drop — it needs its Load #.\n\n'
          'Add a line like "LOAD # 1234" at the top, then send. The same Load # sent again becomes the next leg of that load.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('addLoadNoLine'),
          onPressed: () {
            input.text = 'LOAD # \n${text.trimLeft()}';
            input.selection = const TextSelection.collapsed(offset: 7);
            Get.back();
          },
          child: const Text('Add LOAD # line'),
        ),
      ],
    ),
  );
  return true;
}
