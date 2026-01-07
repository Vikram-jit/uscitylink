import 'package:chat_app/web_badge_interop.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get the token for testing
      String? token = await _firebaseMessaging.getToken(
        vapidKey:
            "BDZMkcVLdoIBDTOoupaI0DZ_HEBwpyJG94l12sYN8iPuKeKHsAlB_nfvHyq_EgrhgAv69f3efuhccroyxQD1lxs",
      );
      print("FCM Token: $token");

      // 2. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');

        // A. Show Visual Alert (Dialog)
        if (message.notification != null) {
          // _showForegroundAlertDialog(context, message);
        }

        // B. Update Badge
        if (message.data.containsKey('badgeCount')) {
          int count = int.tryParse(message.data['badgeCount'].toString()) ?? 0;
          // WebBadgeService.setBadge(count);
        }
      });
    }
  }

  // void _showForegroundAlertDialog(BuildContext context, RemoteMessage message) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(message.notification?.title ?? "Notification"),
  //       content: Text(message.notification?.body ?? ""),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             // Clear badge when user reads the alert
  //             //WebBadgeService.clearBadge();
  //             Navigator.of(context).pop();
  //           },
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
