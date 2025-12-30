import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class MobileHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.primary, title: Text("Slack")),
      drawer: Drawer(child: Text("Channels")),
      body: Center(
        child: Text(
          "Chat Area (Mobile)",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
