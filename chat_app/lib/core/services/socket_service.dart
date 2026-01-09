import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  bool get isConnected => socket?.connected ?? false;

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
  }

  void listenNotifications({
    required void Function(String message) onNotification,
    required void Function(String message) onNotificationId,
    required void Function(dynamic data) onOnlineDriverFn,
  }) {
    if (socket == null) return;

    socket!.off('notification_new_message');
    socket!.off('notification_user_id');
    socket!.off('user_online_driver_web');

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
  }

  void _registerBaseListeners() {
    socket?.on('connect', (_) {
      debugPrint('🟢 Socket connected: ${socket?.id}');
    });

    socket?.on('disconnect', (_) {
      debugPrint('🔴 Socket disconnected');
    });

    socket?.on('connect_error', (err) {
      debugPrint('❌ Socket connect error: $err');
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
