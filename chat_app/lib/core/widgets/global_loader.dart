import 'package:chat_app/core/controller/global_loader_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalLoader extends StatelessWidget {
  const GlobalLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GlobalLoaderController>();

    return Obx(() {
      if (!controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF4A154B), // Slack purple
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
