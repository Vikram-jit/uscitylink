// lib/modules/template/views/template_screen.dart

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/template_controller.dart';
import 'package:chat_app/modules/template/widgets/template_delete_dialog.dart';
import 'package:chat_app/modules/template/widgets/template_form_dialog.dart'
    hide TemplateDeleteDialog;
import 'package:chat_app/modules/template/widgets/template_row.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateScreen extends StatelessWidget {
  TemplateScreen({super.key});

  final TemplateController _c =
      Get.isRegistered<TemplateController>(tag: 'screen')
      ? Get.find<TemplateController>(tag: 'screen')
      : Get.put(TemplateController(), tag: 'screen');
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TemplateHeader(c: _c),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          Expanded(child: _TemplateBody(c: _c)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _TemplateHeader extends StatelessWidget {
  final TemplateController c;
  const _TemplateHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Templates',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                Obx(
                  () => Text(
                    '${c.totalItems.value} templates',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => TemplateFormDialog.show(context, c, null),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'New Template',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────

class _TemplateBody extends StatelessWidget {
  final TemplateController c;
  const _TemplateBody({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Initial loader
      if (c.isLoading.value && c.templates.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        );
      }

      // Empty state
      if (c.templates.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.article_outlined,
                size: 48,
                color: Color(0xFFCCCCCC),
              ),
              const SizedBox(height: 12),
              Text(
                'No templates yet',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Table header
          Container(
            color: const Color(0xFFF8F8F8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Row(
              children: [
                _ColHeader('TITLE', flex: 2),
                _ColHeader('BODY', flex: 4),
                _ColHeader('ATTACHMENT', flex: 2),
                _ColHeader('ACTIONS', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),

          // Rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: c.templates.length + (c.isLoading.value ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
              itemBuilder: (context, i) {
                if (i == c.templates.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                final template = c.templates[i];
                return TemplateRow(
                  key: ValueKey(template.id),
                  template: template,
                  onEdit: () => TemplateFormDialog.show(context, c, template),
                  onDelete: () =>
                      TemplateDeleteDialog.show(context, c, template),
                );
              },
            ),
          ),

          // Footer
          Obx(
            () => !c.isLoading.value && !c.hasMore
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'All ${c.totalItems.value} templates loaded',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 4),
          ),
        ],
      );
    });
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
