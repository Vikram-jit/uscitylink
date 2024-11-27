import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uscitylink/services/fcm_service.dart';
import 'package:uscitylink/services/splash_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/routes/app_routes.dart'; // Add this import for your routes

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  SplashService splashService = SplashService();

  @override
  void initState() {
    super.initState();
    // Handle initial navigation when app is launched from a notification

    // Check if the user is logged in or not
    splashService.isLogin();
  }

  // Function to handle initial notification (when the app is launched from a notification)

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TColors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: TColors.primary,
        ),
      ),
    );
  }
}
