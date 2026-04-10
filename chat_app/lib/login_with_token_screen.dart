import 'package:chat_app/core/controller/login_with_token_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginWithTokenScreen extends StatelessWidget {
  const LoginWithTokenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lazily put the controller — it reads Get.arguments in onInit
    final controller = Get.put(LoginWithTokenController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Obx(() {
          // ── Loading ──
          if (controller.isLoading.value) {
            return _LoadingCard();
          }

          // ── Result ──
          return _ResultCard(
            isSuccess: controller.isSuccess.value,
            message: controller.message.value,
          );
        }),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6C3FC4),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Authenticating…',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1730),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait while we verify your token.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF9B97A8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Result card — equivalent to the MUI Alert
// ─────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const _ResultCard({required this.isSuccess, required this.message});

  @override
  Widget build(BuildContext context) {
    final (bg, border, iconColor, icon) = isSuccess
        ? (
            const Color(0xFFEAF3DE),
            const Color(0xFF639922),
            const Color(0xFF3B6D11),
            Icons.check_circle_rounded,
          )
        : (
            const Color(0xFFFCEBEB),
            const Color(0xFFE24B4A),
            const Color(0xFFA32D2D),
            Icons.error_rounded,
          );

    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alert banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message.isNotEmpty
                        ? message
                        : isSuccess
                        ? 'Login successful! Redirecting to dashboard…'
                        : 'Something went wrong.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isSuccess) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3FC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
