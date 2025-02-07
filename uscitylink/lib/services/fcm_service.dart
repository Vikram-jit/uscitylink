import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/controller/message_controller.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/controller/staff/staffchat_controller.dart';
import 'package:uscitylink/controller/user_preference_controller.dart';
import 'package:uscitylink/model/training_model.dart';
import 'dart:io' show Platform;

import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/auth_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'package:uscitylink/views/driver/views/trainings/training_detail_view.dart';

class FCMService extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  UserPreferenceController userPreferenceController =
      UserPreferenceController();

  AuthService _authService = AuthService();
  ChannelController _channelController = Get.put(ChannelController());
  MessageController _messageController = Get.put(MessageController());
  StaffchatController _staffchatController = Get.put(StaffchatController());

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
            'ic_launcher'); // Make sure to add an icon to your assets

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
      socketService.connectSocket();
      if (payload.isNotEmpty) {
        try {
          var decodedPayload = jsonDecode(payload);
          print(decodedPayload);
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
          } else if (decodedPayload["type"] == "DRIVER NEW MESSAGE") {
            if (decodedPayload["isActiveChannel"] == "0") {
              if (Get.isRegistered<StaffchannelController>()) {
                Get.find<StaffchannelController>()
                    .updateActiveChannel(decodedPayload['channelId']);
              }
            }
            if (AppRoutes.driverMessage.isNotEmpty) {
              if (socketService.isConnected.value) {
                socketService.staffUnreadAllUserMessage(
                    decodedPayload['channelId'], decodedPayload['userId']);
              }

              // If already on the target screen, just update the state or pop the stack
              if (Get.currentRoute == AppRoutes.staff_user_message) {
                _staffchatController.channelId.value =
                    decodedPayload['channelId'];
                _staffchatController.userName.value = decodedPayload['title'];
                _staffchatController.updateChannelMessagesByNotification(
                    decodedPayload['channelId'],
                    decodedPayload['title'],
                    decodedPayload['userId']);
              } else {
                if (socketService.isConnected.value) {
                  socketService.staffUnreadAllUserMessage(
                      decodedPayload['channelId'], decodedPayload['userId']);
                }
                Get.back();
                Get.toNamed(
                  AppRoutes.staff_user_message,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['title'],
                    'userId': decodedPayload['userId']
                  },
                );
              }
            }
          } else if (decodedPayload['type'] == "GROUP NEW MESSAGE STAFF") {
            if (AppRoutes.staffGroupMessage.isNotEmpty) {
              if (decodedPayload["isActiveChannel"] == "0") {
                if (Get.isRegistered<StaffchannelController>()) {
                  Get.find<StaffchannelController>()
                      .updateActiveChannel(decodedPayload['channelId']);
                }
              }
              if (Get.currentRoute == AppRoutes.staffGroupMessage) {
                socketService.updateStaffGroup(decodedPayload['groupId']);

                Get.back();

                if (Get.isRegistered<GroupController>()) {
                  Get.find<GroupController>().currentPage.value = 1;
                  Get.find<GroupController>().totalPages.value = 1;
                  Get.find<GroupController>().messages.value = [];
                }
                Get.toNamed(
                  AppRoutes.staffGroupMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['title'],
                    'groupId': decodedPayload['groupId']
                  },
                );
              } else {
                Get.toNamed(
                  AppRoutes.staffGroupMessage,
                  arguments: {
                    'channelId': decodedPayload['channelId'],
                    'name': decodedPayload['title'],
                    'groupId': decodedPayload['groupId']
                  },
                );
              }
            }
          } else if (decodedPayload['type'] == "TRAINING_VIDEO") {
            Training dashboard =
                Training.fromJson(jsonDecode(decodedPayload['training']));
            Get.to(() => TrainingDetailView(
                tiitle: decodedPayload['title'],
                id: decodedPayload['id'],
                trainings: dashboard.trainings!,
                training: dashboard));
          } else {
            if (AppRoutes.driverMessage.isNotEmpty) {
              socketService.updateActiveChannel(decodedPayload['channelId']);
              // If already on the target screen, just update the state or pop the stack
              if (Get.currentRoute == AppRoutes.driverMessage) {
                _messageController.channelId.value =
                    decodedPayload['channelId'];
                _messageController.name.value = decodedPayload['title'];
                _messageController.updateChannelMessagesByNotification(
                    decodedPayload['channelId'], decodedPayload['title']);
              } else {
                socketService.updateActiveChannel(decodedPayload['channelId']);
                Get.back();
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
      userPreferenceController.getToken().then((value) async {
        if (value == null || value.isEmpty) {
        } else {
          await updateDeviceToken(token);
        }
      });
    }

    // Listen to token refresh events
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      fcmToken.value = newToken;
      await updateDeviceToken(newToken); // Update token if it changes
    });

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Received a message in the foreground:');
      // Initialize the badge count to 0
      var data = jsonEncode(message.data);

      _channelController.getCount();
      _showNotification(data, message.notification?.title ?? '',
          message.notification?.body ?? '');
      // }
    });

    //App IN BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      var decodedPayload = message.data;

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
      } else if (decodedPayload["type"] == "DRIVER NEW MESSAGE") {
        if (decodedPayload["isActiveChannel"] == "0") {
          if (Get.isRegistered<StaffchannelController>()) {
            Get.find<StaffchannelController>()
                .updateActiveChannel(decodedPayload['channelId']);
          }
        }
        if (AppRoutes.driverMessage.isNotEmpty) {
          if (socketService.isConnected.value) {
            socketService.staffUnreadAllUserMessage(
                decodedPayload['channelId'], decodedPayload['userId']);
          }

          // If already on the target screen, just update the state or pop the stack
          if (Get.currentRoute == AppRoutes.staff_user_message) {
            _staffchatController.channelId.value = decodedPayload['channelId'];
            _staffchatController.userName.value = decodedPayload['title'];
            _staffchatController.updateChannelMessagesByNotification(
                decodedPayload['channelId'],
                decodedPayload['title'],
                decodedPayload['userId']);
          } else {
            if (socketService.isConnected.value) {
              socketService.staffUnreadAllUserMessage(
                  decodedPayload['channelId'], decodedPayload['userId']);
            }
            Get.back();
            Get.toNamed(
              AppRoutes.staff_user_message,
              arguments: {
                'channelId': decodedPayload['channelId'],
                'name': decodedPayload['title'],
                'userId': decodedPayload['userId']
              },
            );
          }
        }
      } else if (decodedPayload['type'] == "GROUP NEW MESSAGE STAFF") {
        if (AppRoutes.staffGroupMessage.isNotEmpty) {
          if (decodedPayload["isActiveChannel"] == "0") {
            if (Get.isRegistered<StaffchannelController>()) {
              Get.find<StaffchannelController>()
                  .updateActiveChannel(decodedPayload['channelId']);
            }
          }
          if (Get.currentRoute == AppRoutes.staffGroupMessage) {
            socketService.updateStaffGroup(decodedPayload['groupId']);

            Get.back();

            if (Get.isRegistered<GroupController>()) {
              Get.find<GroupController>().currentPage.value = 1;
              Get.find<GroupController>().totalPages.value = 1;
              Get.find<GroupController>().messages.value = [];
            }
            Get.toNamed(
              AppRoutes.staffGroupMessage,
              arguments: {
                'channelId': decodedPayload['channelId'],
                'name': decodedPayload['title'],
                'groupId': decodedPayload['groupId']
              },
            );
          } else {
            Get.toNamed(
              AppRoutes.staffGroupMessage,
              arguments: {
                'channelId': decodedPayload['channelId'],
                'name': decodedPayload['title'],
                'groupId': decodedPayload['groupId']
              },
            );
          }
        }
      } else if (decodedPayload['type'] == "TRAINING_VIDEO") {
        Training dashboard =
            Training.fromJson(jsonDecode(decodedPayload['training']));
        Get.to(() => TrainingDetailView(
            tiitle: decodedPayload['title'],
            id: decodedPayload['id'],
            trainings: dashboard.trainings!,
            training: dashboard));
      } else {
        if (AppRoutes.driverMessage.isNotEmpty) {
          socketService.updateActiveChannel(decodedPayload['channelId']);
          // If already on the target screen, just update the state or pop the stack
          if (Get.currentRoute == AppRoutes.driverMessage) {
            _messageController.channelId.value = decodedPayload['channelId'];
            _messageController.name.value = decodedPayload['title'];
            _messageController.updateChannelMessagesByNotification(
                decodedPayload['channelId'], decodedPayload['title']);
          } else {
            socketService.updateActiveChannel(decodedPayload['channelId']);
            Get.back();
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
    });

    // Handle background messages
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    //WHEN APP  TERMINATED
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (message != null) {
        socketService.connectSocket();
        // Handle the notification and navigate to the desired screen
        var data = message.data;
        print(data);
        if (data['type'] == "GROUP MESSAGE") {
          Utils.showLoader();
          Timer(const Duration(seconds: 3), () {
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
            Utils.hideLoader();
          });
        } else if (data['type'] == "GROUP NEW MESSAGE STAFF") {
          Utils.showLoader();
          Timer(const Duration(seconds: 3), () {
            socketService.updateStaffGroup(data['groupId']);
            socketService.socket
                .emit("staff_channel_update", data['channelId']);
            Get.toNamed(
              AppRoutes.staffGroupMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title'],
                'groupId': data['groupId']
              },
            );
            Utils.hideLoader();
          });
        } else if (data['type'] == "DRIVER NEW MESSAGE") {
          Utils.showLoader();
          Timer(const Duration(seconds: 3), () {
            if (socketService.isConnected.value) {
              socketService.staffUnreadAllUserMessage(
                  data['channelId'], data['userId']);
              socketService.socket
                  .emit("staff_channel_update", data['channelId']);
            }

            // if (data["isActiveChannel"] == "0") {
            //   Get.put(StaffchannelController())
            //       .updateActiveChannel(data['channelId']);
            // }

            Get.toNamed(
              AppRoutes.staff_user_message,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title'],
                'userId': data['userId']
              },
            );
            Utils.hideLoader();
          });
        } else if (data['type'] == "TRAINING_VIDEO") {
          Utils.showLoader();
          Timer(const Duration(seconds: 3), () {
            Training dashboard =
                Training.fromJson(jsonDecode(data['training']));
            Get.to(() => TrainingDetailView(
                tiitle: data['title'],
                id: data['id'],
                trainings: dashboard.trainings!,
                training: dashboard));
            Utils.hideLoader();
          });
        } else {
          Utils.showLoader();
          Timer(
            const Duration(seconds: 3),
            () => Get.toNamed(
              AppRoutes.driverMessage,
              arguments: {
                'channelId': data['channelId'],
                'name': data['title'],
              },
            ),
          );
          Utils.hideLoader();
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
      if (Platform.version.startsWith('33') || Platform.isAndroid) {
        // Android 13+ (API 33) requires runtime permission to post notifications
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('Android permissions granted.');
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          print('Android provisional permission granted.');
        } else {
          print('Android permission denied.');
        }
      } else {
        // For Android 12 and below, FirebaseMessaging automatically handles permissions.
        print('Android 12 and below: Permissions are granted automatically');
      }
    }
  }

  // Show local notification (Android & iOS)
  Future<void> _showNotification(
      String payload, String title, String body) async {
    // Android specific details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // The same channel ID used when creating the channel
      'High Importance Notifications',
      channelDescription:
          'This channel is used for high importance notifications.',
      importance: Importance.high, // High priority
      priority: Priority.high, // High priority
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
  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.notification?.title}');
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // The same channel ID used when creating the channel
      'High Importance Notifications',
      channelDescription:
          'This channel is used for high importance notifications.',
      importance: Importance.high, // High priority
      priority: Priority.high, // High priority
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
