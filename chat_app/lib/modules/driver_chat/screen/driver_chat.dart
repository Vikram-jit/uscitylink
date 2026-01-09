import 'package:chat_app/core/responsive/responsive_layout.dart';
import 'package:chat_app/modules/driver_chat/views/desktop_view.dart';
import 'package:chat_app/modules/home/views/mobile_home.dart';

import 'package:chat_app/modules/home/views/web_home.dart';
import 'package:flutter/material.dart';

class DriverChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileHomeView(),
      tablet: WebHomeView(),
      desktop: DesktopView(),
    );
  }
}
