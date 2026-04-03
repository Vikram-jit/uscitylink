// lib/modules/template/views/widgets/template_row.dart

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateRow extends StatefulWidget {
  final Template template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TemplateRow({
    super.key,
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TemplateRow> createState() => _TemplateRowState();
}

class _TemplateRowState extends State<TemplateRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final hasMedia = t.url != null && t.url!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFFFAFAFA) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Title
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEF4),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  t.name ?? 'Unnamed',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Body
            Expanded(
              flex: 4,
              child: Text(
                t.body ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            // Attachment
            Expanded(
              flex: 2,
              child: hasMedia
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: MediaComponent(
                          messageId: t.id?.toString() ?? '',
                          url: t.url!,
                          fileName: t.url!,
                          uploadType: 'server',
                          messageDirection: 'S',
                          type: GallertType.MessageFiles,
                        ),
                      ),
                    )
                  : Text(
                      '—',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFCCCCCC),
                        fontSize: 13,
                      ),
                    ),
            ),

            // Actions
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    color: AppColors.linkBlue,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    color: const Color(0xFFE53935),
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action button ──

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 16, color: widget.color),
          ),
        ),
      ),
    );
  }
}
