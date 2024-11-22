import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'dart:io' show Platform;

import 'package:uscitylink/services/auth_service.dart';

class FCMService extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AuthService _authService = AuthService();
  // The token for FCM
  RxString fcmToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Request permissions for iOS or Android
    await _requestPermissions();

    // Get the FCM token for this device
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      fcmToken.value = token;
      await updateDeviceToken(token);
    }

    // Listen to token refresh events
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      fcmToken.value = newToken;

      await updateDeviceToken(newToken); // Update token if it changes
    });

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Received a message in the foreground: ${message.notification?.title}');
      // Handle foreground messages, you can show a local notification here
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Navigate to the appropriate screen
    });
  }

  // Request permissions for notifications on iOS and Android
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS permission request
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('iOS permissions granted.');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('iOS provisional permission granted.');
      } else {
        print('iOS permission denied.');
      }
    } else if (Platform.isAndroid) {
      // Android permission request
      NotificationSettings settings =
          await _firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Android permissions granted.');
      } else {
        print('Android permissions not granted.');
      }
    }
  }

  // Handler for background messages
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.notification?.title}');
    // You can show a local notification or handle the data here
  }

  // Method to show local notifications (optional)
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      final data = DeviceTokenUpdate(
        token: token,
        platform: Platform.operatingSystem, // Send platform info (iOS/Android)
      );
      await _authService
          .updateDeviceToken(data); // Send the token to the backend
      print('Device token updated on the server');
    } catch (e) {
      print('Error updating device token: $e');
    }
  }
}
