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
    splashService.isLogin();
  }

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
