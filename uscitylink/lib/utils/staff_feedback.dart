import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Error / info banner for the staff app, shown at the BOTTOM above the tab bar.
///
/// The shared `Utils.snackBar` shows at the top of the screen, right over the menu / back button,
/// and while it is visible it takes the tap — so a failed request made the drawer impossible to
/// open. Staff screens use this instead; driver screens keep `Utils.snackBar` unchanged.
void staffSnackBar(String title, String message) {
  Get.snackbar(
    title,
    message.replaceFirst(RegExp(r'^Exception:\s*'), ''),
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 84),
    borderRadius: 14,
    backgroundColor: const Color(0xFF0F172A),
    colorText: Colors.white,
    icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
    duration: const Duration(seconds: 4),
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
}
