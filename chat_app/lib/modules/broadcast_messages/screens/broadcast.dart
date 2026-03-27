import 'package:chat_app/core/responsive/responsive_layout.dart';
import 'package:chat_app/modules/broadcast_messages/views/desktop_view.dart';
import 'package:chat_app/modules/broadcast_messages/views/mobile_view.dart';
import 'package:flutter/material.dart';

class Broadcast extends StatelessWidget {
  const Broadcast({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: MobileView(),
      tablet: DesktopView(),
      desktop: DesktopView(),
    );
  }
}
