import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// Browser Notification Service
// Uses package:web (modern 2026 standard — works on Web + Wasm)
// ─────────────────────────────────────────────────────────────

class BrowserNotificationService {
  BrowserNotificationService._();

  static bool get _isSupported =>
      kIsWeb && web.window.hasProperty('Notification'.toJS).toDart;

  // ── Permission ───────────────────────────────────────────────

  /// Returns current permission: "granted" | "denied" | "default"
  static String get permission {
    if (!_isSupported) return 'denied';
    return web.Notification.permission;
  }

  static bool get isGranted => permission == 'granted';
  static bool get isDenied => permission == 'denied';

  /// Request permission from the browser.
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    if (isGranted) return true;
    if (isDenied) return false;

    final result = await web.Notification.requestPermission().toDart;
    return result == 'granted';
  }

  // ── Show notification ─────────────────────────────────────────

  /// Shows a browser notification.
  /// Automatically requests permission if not yet granted.
  static Future<void> show({
    required String title,
    String body = '',
    String? icon,
    String? tag,
    bool silent = false,
  }) async {
    print(_isSupported);

    if (!_isSupported) return;

    // Request if not decided yet
    if (!isGranted) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    final options = web.NotificationOptions(
      body: body,
      icon: icon ?? '/icons/Icon-192.png',
      tag: tag ?? 'chat-notification',
      silent: silent,
    );
    try {
      final notification = web.Notification(title, options);

      Future.delayed(const Duration(seconds: 6), () {
        notification.close();
      });
    } catch (e) {
      print(e);
    }

    // Auto-close after 6 seconds
  }

  // ── Convenience wrappers ──────────────────────────────────────

  static Future<void> showMessage({
    required String senderName,
    required String message,
    String? icon,
  }) => show(
    title: senderName,
    body: message.length > 100 ? '${message.substring(0, 97)}…' : message,
    icon: icon,
    tag: 'msg-$senderName',
  );

  static Future<void> showMediaMessage({
    required String senderName,
    String? icon,
  }) => show(
    title: senderName,
    body: '📎 Sent an attachment',
    icon: icon,
    tag: 'media-$senderName',
  );
}
