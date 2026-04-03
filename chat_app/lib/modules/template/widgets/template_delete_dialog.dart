// lib/modules/template/views/dialogs/template_delete_dialog.dart

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/controllers/template_controller.dart';
import 'package:chat_app/modules/home/models/template_model.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateDeleteDialog extends StatefulWidget {
  final Template template;
  final TemplateController controller;

  const TemplateDeleteDialog._({
    required this.template,
    required this.controller,
  });

  static void show(
    BuildContext context,
    TemplateController controller,
    Template template,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // ← prevent dismiss while deleting
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) =>
          TemplateDeleteDialog._(controller: controller, template: template),
    );
  }

  @override
  State<TemplateDeleteDialog> createState() => _TemplateDeleteDialogState();
}

class _TemplateDeleteDialogState extends State<TemplateDeleteDialog> {
  // ── Local flag — never rely on controller.isLoading
  //    because that's shared with list fetches ──
  bool _isDeleting = false;

  Future<void> _onDelete() async {
    // ── Guard: ignore tap if already in-flight ──
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      final ok = await widget.controller.deleteTemplate(
        widget.template.id.toString(),
      );

      if (!mounted) return;

      if (ok) {
        // ── Pop exactly once ──
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 300));
        AppSnackbar.success('Template deleted.');
      } else {
        // ── Stay open so user can retry ──
        setState(() => _isDeleting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ── Block back-swipe/button while deleting ──
      canPop: !_isDeleting,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        elevation: 12,
        insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
              _buildBody(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFE53935),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delete Template',
              style: GoogleFonts.poppins(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          // ── Hide close button while deleting ──
          if (!_isDeleting)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.secondaryText,
                    size: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this template?',
            style: GoogleFonts.poppins(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              constraints: const BoxConstraints(maxWidth: 140),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EEF4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                widget.template.name ?? 'Unnamed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFE53935),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel — disabled while deleting
          OutlinedButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE8E8E8)),
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white,
              foregroundColor: AppColors.secondaryText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),

          // Delete button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isDeleting
                ? Container(
                    key: const ValueKey('loading'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    key: const ValueKey('delete'),
                    onPressed: _onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
