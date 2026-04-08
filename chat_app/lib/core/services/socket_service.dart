import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web/web.dart' as web; // Modern 2026 standard for Web/Wasm

class SocketService extends GetxController {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();
  final RxBool isReconnecting = false.obs;
  IO.Socket? socket;
  Timer? _pingTimer;
  bool get isConnected => socket?.connected ?? false;
  bool _isReconnectingShown = false;

  /// 🔌 Connect socket with auth token
  void connect(String token) {
    // Prevent duplicate connections
    if (socket != null && socket!.connected) return;

    socket = IO.io(
      "http://52.9.12.189:4300",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .disableAutoConnect()
          .build(),
    );

    _registerBaseListeners();
    socket!.connect();
    _startPingCheck(token); // 👈 add this
  }

  void _startPingCheck(String token) {
    _pingTimer?.cancel();

    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (socket == null) return;

      if (!socket!.connected) {
        debugPrint("⚠️ Socket not connected. Reconnecting...");

        try {
          socket!.connect();
        } catch (e) {
          debugPrint("Reconnect failed: $e");

          // fallback recreate socket (important)
          disconnect();
          connect(token);
        }
      } else {
        // Optional: send ping event
        socket!.emit("ping", {"time": DateTime.now().toIso8601String()});
        debugPrint("✅ Socket alive");
      }
    });
  }

  void listenNotifications({
    required void Function(String message) onNotification,
    required void Function(String message) onNotificationId,
    required void Function(dynamic data) onOnlineDriverFn,
    required void Function(dynamic data) onNewMessageWithUser,
    required void Function(dynamic data) onTypingDriver,
  }) {
    if (socket == null) return;

    socket!.off('notification_new_message');
    socket!.off('notification_user_id');
    socket!.off('user_online_driver_web');
    socket!.off('notification_new_message_with_user');
    socket!.off('typingUserWeb');

    socket!.on("typingUserWeb", (data) {
      print(jsonEncode(data));
      onTypingDriver(data);
    });

    socket!.on('notification_new_message', (data) {
      final message = data.toString();
      onNotification(message);
    });
    socket!.on('notification_user_id', (data) {
      final message = data.toString();
      onNotificationId(message);
    });

    socket!.on("user_online_driver_web", (data) {
      onOnlineDriverFn(data);
    });

    socket!.on("notification_new_message_with_user", onNewMessageWithUser);
  }

  void _registerBaseListeners() {
    socket?.on('connect', (_) {
      debugPrint('🟢 Socket connected: ${socket?.id}');
      if (isReconnecting.value) {
        isReconnecting.value = false;

        debugPrint("🔄 Reloading app after reconnect...");
        web.window.location.reload(); // 👈 reload page
      }
    });

    socket?.on('disconnect', (_) {
      debugPrint('🔴 Socket disconnected');
      isReconnecting.value = true;
    });

    socket?.on('connect_error', (err) {
      debugPrint('❌ Socket connect error: $err');
      isReconnecting.value = true;
    });

    socket?.on('reconnect_attempt', (_) {
      debugPrint('🔄 Reconnecting...');
      isReconnecting.value = true;
    });
  }

  void emit(String event, dynamic data) {
    if (socket == null || !socket!.connected) {
      debugPrint('⚠️ Socket not connected. Event dropped: $event');
      return;
    }
    socket!.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket?.off(event);
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void disconnect() {
    if (socket == null) return;

    socket!.clearListeners();
    socket!.disconnect();
    socket!.dispose();
    socket = null;

    debugPrint('🧹 Socket disposed');
  }
}
