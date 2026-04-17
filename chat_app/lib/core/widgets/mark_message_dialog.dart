import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class MarkMessageDialog extends StatelessWidget {
  final bool open;
  final VoidCallback onClose;
  final VoidCallback onSendOtp;
  final bool loader;

  const MarkMessageDialog({
    super.key,
    required this.open,
    required this.onClose,
    required this.onSendOtp,
    required this.loader,
  });

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox();

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Mark all messages as read",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// CONTENT
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "This will mark all unread messages as read. This action cannot be undone.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loader ? null : onClose,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: loader ? null : onSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: loader
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Mark as Read",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
