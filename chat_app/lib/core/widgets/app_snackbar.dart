import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void success(String message, {String title = "Success"}) {
    _show(
      title: title,
      message: message,
      color: const Color(0xFF4A154B), // Slack purple
      icon: Icons.check_circle,
    );
  }

  static void error(String message, {String title = "Error"}) {
    _show(title: title, message: message, color: Colors.red, icon: Icons.error);
  }

  static void info(String message, {String title = "Info"}) {
    _show(title: title, message: message, color: Colors.blue, icon: Icons.info);
  }

  static void warning(String message, {String title = "Warning"}) {
    _show(
      title: title,
      message: message,
      color: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
        boxShadows: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
        ],
        messageText: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
