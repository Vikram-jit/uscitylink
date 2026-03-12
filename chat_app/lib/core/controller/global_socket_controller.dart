import 'dart:convert';

import 'package:chat_app/core/services/user_interaction_service.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/controllers/overview_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
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
    final token = StorageService.syncGetToken();

    if (token != null && token.isNotEmpty) {
      _socket.connect(token); // ✅ connect socket
    }
    if (_socket.socket?.connected == true) {
      print("🟢 Socket already connected");
    } else {
      print("🔴 Socket not connected yet");
    }
    _registerGlobalListeners();
  }

  void _registerGlobalListeners() {
    // 🔔 Global notification
    _socket.listenNotifications(
      onNotification: _handleNotification,
      onNotificationId: _handleNotificationId,
      onOnlineDriverFn: _handleOnlineDriverFn,
      onNewMessageWithUser: _handleNewMessageWithUser,
    );
  }

  // ---------- HANDLERS ----------

  void _handleNewMessageWithUser(dynamic data) async {
    UserChannels userChannels = UserChannels.fromJson(data);
    if (Get.isRegistered<ChannelController>()) {
      Get.find<ChannelController>().replaceChannelMember(userChannels);
    }
  }

  void _handleOnlineDriverFn(dynamic data) async {
    if (Get.isRegistered<OverviewController>()) {
      Get.find<OverviewController>().handleDriverOnlineEvent(data);
      Get.find<OverviewController>().handleDriverOnlineForChatHeader(data);
    }
    if (Get.isRegistered<ChannelController>()) {
      Get.find<ChannelController>().handleDriverOnlineEvent(data);
    }
  }

  void _handleNotification(dynamic message) async {
    _playCount = 0; // Reset counter for new notification
    final interaction = Get.find<UserInteractionService>();

    // 🔕 If user never interacted → NO SOUND (but show snackbar)
    if (!interaction.hasInteracted.value) {
      Get.snackbar(
        "New Message Reciveds",
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
      return;
    }

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
      "New Message Recivedss",
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
    if (Get.isRegistered<ChannelController>()) {
      Get.find<ChannelController>().incrementUnreadCountByProfileId(driverId);
    }
  }
}
