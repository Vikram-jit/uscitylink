import 'package:flutter/material.dart';
import '../../core/responsive/responsive_layout.dart';
import 'views/mobile_home.dart';
import 'views/web_home.dart';
import 'views/desktop_home.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileHomeView(),
      tablet: WebHomeView(),
      desktop: DesktopHomeView(),
    );
  }
}
