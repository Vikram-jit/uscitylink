import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/socket_service.dart';

class BackgroundService {
  static void start() async {
    final service = FlutterBackgroundService();
    // Ensure SocketService is properly registered with GetX
    SocketService socketService = Get.find<SocketService>();

    // Configure the background service
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: onStart,
        isForegroundMode:
            true, // Foreground service with persistent notification
        autoStartOnBoot: true,
      ),
    );

    // Start the service
    service.startService();
  }

  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant
        .ensureInitialized(); // Required for iOS background execution

    // Handle the stop event
    service.on("stop").listen((event) {
      service.stopSelf();
      print("Foreground process stopped.");
    });

    service.on("start").listen((event) {
      print("Foreground process started.");
    });

    // Perform some background work periodically
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (service is AndroidServiceInstance) {
        service.invoke("setAsForeground");
      }
      print("Foreground task is running...");
    });

    // Ensure socket service is connected before sending pings
    // SocketService socketService = Get.put(SocketService());
    // if (socketService.isConnected.value) {
    //   Timer.periodic(const Duration(seconds: 15), (timer) {
    //     if (socketService.isConnected.value) {
    //       print('Sending ping...');
    //       socketService.socket
    //           .emit('ping'); // Send the ping message to the server
    //     } else {
    //       timer.cancel(); // Stop pinging if disconnected
    //     }
    //   });
    // }
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized(); // Ensure initialization for iOS

    // Perform background work when the app is in the background
    Timer.periodic(Duration(seconds: 15), (timer) {
      print("Background task running on iOS...");
    });

    return true;
  }
}
