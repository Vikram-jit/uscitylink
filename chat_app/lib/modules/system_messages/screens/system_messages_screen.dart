import 'package:chat_app/core/responsive/responsive_layout.dart';
import 'package:chat_app/modules/system_messages/views/desktop_view.dart';
import 'package:flutter/material.dart';

class SystemMessagesScreen extends StatelessWidget {
  const SystemMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const SystemMessagesDesktopView(),
      tablet: const SystemMessagesDesktopView(),
      desktop: const SystemMessagesDesktopView(),
    );
  }
}
