import 'dart:io';

import 'package:flutter/services.dart';

/// Android: lets the call screen show over the lock screen, so a call answered on a locked phone
/// can be talked on without unlocking (MainActivity.kt). Only on while the call screen is open
/// during a call: chats and the rest of the app stay behind the lock.
class LockScreen {
  static const _channel = MethodChannel('uscitylink/lock_screen');
  static bool? _on;

  static Future<void> showCallOverLock(bool on) async {
    if (!Platform.isAndroid || _on == on) return;
    _on = on;
    try {
      await _channel.invokeMethod('showWhenLocked', {'on': on});
    } catch (_) {
      _on = null; // try again next time
    }
  }
}
