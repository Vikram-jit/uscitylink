import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DialogToast {
  static void show({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.green,
    IconData icon = Icons.check_circle,
  }) {
    // Get overlay
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20, // Show at top
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    overlay?.insert(overlayEntry);

    // Auto remove
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
