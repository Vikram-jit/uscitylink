import 'dart:convert';

import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/socket_service.dart';
import 'package:audioplayers/audioplayers.dart';

class GlobalSocketController extends GetxController {
  final _socket = SocketService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _playCount = 0;
  final int _maxPlays = 2;
  @override
  void onInit() {
    super.onInit();
    _registerGlobalListeners();
  }

  void _registerGlobalListeners() {
    // 🔔 Global notification
    _socket.listenNotifications(
      onNotification: _handleNotification,
      onNotificationId: _handleNotificationId,
    );
  }

  // ---------- HANDLERS ----------

  void _handleNotification(dynamic message) async {
    _playCount = 0; // Reset counter for new notification

    // Listen for completion to repeat the sound
    final subscription = _audioPlayer.onPlayerComplete.listen((event) async {
      _playCount++;
      if (_playCount < _maxPlays) {
        await _audioPlayer.resume(); // Play again
      } else {
        // Stop after 3 times
        await _audioPlayer.stop();
      }
    });
    try {
      await _audioPlayer.play(AssetSource('images/notification.wav'));
    } catch (e) {
      print("Audio play failed: $e");
    }
    Get.snackbar(
      "New Message Recived",
      message ?? "",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(15),
      icon: const Icon(Icons.notifications_active, color: Colors.blue),
      // Optional: Add a button to stop the sound if it's long
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Dismiss"),
      ),
    );
  }

  void _handleNotificationId(String driverId) {
    if (Get.isRegistered<OverviewController>()) {
      Get.find<OverviewController>().incrementUnreadCountByProfileId(driverId);
    }
  }
}
