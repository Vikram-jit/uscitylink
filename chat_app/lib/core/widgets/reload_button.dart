import 'package:chat_app/core/controller/global_loader_controller.dart';
import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/core/widgets/mark_message_dialog.dart';
import 'package:chat_app/modules/home/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

class ReloadButton extends StatelessWidget {
  const ReloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            web.window.location.reload();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.white),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                "Reload",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => MarkMessageDialog(
                open: true,
                loader: false,
                onClose: () => Navigator.pop(context),
                onSendOtp: () async {
                  try {
                    GlobalLoaderController().show();
                    final response = await MessageService()
                        .markAllMessageUnread();
                    if (response.status) {
                      AppSnackbar.success("All messages marked as read");
                      Navigator.pop(context);
                      web.window.location.reload();
                    }
                    throw Exception(response.message);
                  } catch (e) {
                    GlobalLoaderController().hide();
                    AppSnackbar.error(e.toString());
                  }
                },
              ),
            );
          },
          child: Text(
            "Mark all messages as read",
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
