import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;

import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/socket_service.dart';

class FCMService extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AuthService _authService = AuthService();
  RxString fcmToken = ''.obs;

  SocketService socketService = Get.find<SocketService>();

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _initializeFCM();
  }

  // Initialize local notifications for both iOS and Android
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
            'app_icon'); // Make sure to add an icon to your assets

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      String payload = notificationResponse?.payload ?? '';

      if (payload.isNotEmpty) {
        try {
          var decodedPayload = jsonDecode(payload);
          print(payload);
          if (decodedPayload['type'] == "GROUP MESSAGE") {
            if (AppRoutes.driverGroupMessage.isNotEmpty) {
              if (Get.currentRoute == AppRoutes.driverMessage) {
                socketService.addUserToGroup(
                    decodedPayload['channelId'], decodedPayload['groupId']);
                socketService.updateCountGroup(decodedPayload['groupId']);
                Get.back();
                Get.toNamed(
                  AppRoutes.driverGroupMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['name'],
                    'groupId': decodedPayload['groupId']
                  },
                );
              } else {
                Get.toNamed(
                  AppRoutes.driverGroupMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['name'],
                    'groupId': decodedPayload['groupId']
                  },
                );
              }
            }
          } else {
            if (AppRoutes.driverMessage.isNotEmpty) {
              socketService.updateActiveChannel(decodedPayload['channelId']);
              // If already on the target screen, just update the state or pop the stack
              if (Get.currentRoute == AppRoutes.driverMessage) {
                Get.back();
                Get.toNamed(
                  AppRoutes.driverMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['title']
                  },
                );
              } else {
                Get.toNamed(
                  AppRoutes.driverMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['title']
                  },
                );
              }
            }
          }
        } catch (e) {
          print('Error decoding payload: $e');
        }
      } else {
        print('Notification clicked, but no payload');
      }
    });
  }

  // Initialize Firebase Cloud Messaging (FCM)
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
      print('Received a message in the foreground:');

      var data = jsonEncode(message.data);
      print(data);
      // if (data) {

      _showNotification(data, message.notification?.title ?? '',
          message.notification?.body ?? '');
      // }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        // Handle the notification and navigate to the desired screen
        var data = message.data;
        if (data['type'] == "GROUP MESSAGE") {
          Timer(const Duration(seconds: 1), () {
            socketService.addUserToGroup(data['channelId'], data['groupId']);
            socketService.updateCountGroup(data['groupId']);

            Get.toNamed(
              AppRoutes.driverGroupMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['name'],
                'groupId': data['groupId']
              },
            );
          });
        } else {
          Timer(
            const Duration(seconds: 1),
            () => Get.toNamed(
              AppRoutes.driverMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title'],
              },
            ),
          );
        }
      }
    });

    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      var data = message.data;

      if (data['type'] == "GROUP MESSAGE") {
        if (AppRoutes.driverGroupMessage.isNotEmpty) {
          if (Get.currentRoute == AppRoutes.driverMessage) {
            socketService.addUserToGroup(data['channelId'], data['groupId']);
            socketService.updateCountGroup(data['groupId']);
            Get.back();
            Get.toNamed(
              AppRoutes.driverGroupMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['name'],
                'groupId': data['groupId']
              },
            );
          } else {
            Get.toNamed(
              AppRoutes.driverGroupMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['name'],
                'groupId': data['groupId']
              },
            );
          }
        }
      } else {
        if (AppRoutes.driverMessage.isNotEmpty) {
          socketService.updateActiveChannel(data['channelId']);

          if (Get.currentRoute == AppRoutes.driverMessage) {
            Get.back();
            Get.toNamed(
              AppRoutes.driverMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title']
              },
            );
          } else {
            Get.back();
            Get.toNamed(
              AppRoutes.driverMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title']
              },
            );
          }
        }
      }
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

  // Show local notification (Android & iOS)
  Future<void> _showNotification(
      String payload, String title, String body) async {
    // Android specific details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    // iOS specific details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: "",
    );

    // Platform-specific notification details
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification (ID 0 is the notification ID, can be changed)
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails,
        payload: payload);
  }

  // Update the device token to the server (Assuming you have an `updateDeviceToken` method)
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

  // Handler for background messages
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.notification?.title}');

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: "",
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    String? channelId = message.data['channelId'];
    String? title = message.data['title'];
    String? body = message.data['message'];
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title ?? 'No Title',
      body ?? 'No Body',
      platformDetails,
    );
  }
}
