import 'package:chat_app/core/responsive/responsive_layout.dart';
import 'package:chat_app/modules/truck_chat/view/desktop_view.dart';
import 'package:chat_app/modules/truck_chat/view/mobile_view.dart';
import 'package:chat_app/modules/truck_chat/view/web_vierw.dart';
import 'package:flutter/material.dart';

class TruckChat extends StatelessWidget {
  const TruckChat({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileView(),
      tablet: WebVierw(),
      desktop: DesktopView(),
    );
  }
}
