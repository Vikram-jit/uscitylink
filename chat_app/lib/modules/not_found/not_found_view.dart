import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "404 - Page Not Found",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("The page you are looking for doesn't exist."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.offAllNamed("/home"),
              child: const Text("Go Home"),
            ),
          ],
        ),
      ),
    );
  }
}
