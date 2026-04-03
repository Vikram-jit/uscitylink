// lib/modules/template/views/dialogs/_shared_widgets.dart
// Shared small widgets used by both dialogs

import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CloseBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => Get.back(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.secondaryText,
            size: 15,
          ),
        ),
      ),
    );
  }
}

class CancelBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Get.back(),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE8E8E8)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondaryText,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      child: const Text('Cancel'),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        color: AppColors.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}
