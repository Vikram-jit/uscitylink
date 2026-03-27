import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onSubmit;
  final String submitText;
  final bool isLoading;
  final double width;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.onSubmit,
    this.submitText = "Submit",
    this.isLoading = false,
    this.width = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: width,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A154B), Color(0xFF6B2E6C)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              /// ================= CONTENT =================
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),

              /// ================= FOOTER =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: isLoading ? null : () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A154B),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(submitText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
