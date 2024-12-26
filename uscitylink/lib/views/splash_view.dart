import 'package:flutter/material.dart';

import 'package:uscitylink/services/splash_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';

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
        child: CircularProgressIndicator(),
      ),
    );
  }
}
