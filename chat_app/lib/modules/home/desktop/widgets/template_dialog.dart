// widgets/template_dialog.dart

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/template_controller.dart';
import 'package:chat_app/modules/home/models/template_model.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateDialog extends StatefulWidget {
  final void Function(Template template) onSelected;
  const TemplateDialog({super.key, required this.onSelected});

  static void show({required void Function(Template) onSelected}) {
    // ── Always delete stale instance first, then put fresh ──
    Get.delete<TemplateController>(tag: 'template', force: true);
    Get.put(TemplateController(), tag: 'template');

    Get.dialog(
      TemplateDialog(onSelected: onSelected),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
    );
  }

  @override
  State<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<TemplateDialog> {
  late final TemplateController _c;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // ── Safe: controller is guaranteed to exist by show() ──
    _c = Get.find<TemplateController>(tag: 'template');
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    // ── Delete after dialog closes so next open is fresh ──
    Get.delete<TemplateController>(tag: 'template', force: true);
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_c.isLoading.value &&
        _c.hasMore) {
      _c.getTemplates(page: _c.currentPage.value + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(c: _c),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
              Flexible(
                child: _Body(
                  c: _c,
                  scroll: _scroll,
                  onSelected: widget.onSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header — Obx only around count
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TemplateController c;
  const _Header({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Templates',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                // ── totalItems is now .obs so this fires correctly ──
                Obx(
                  () => Text(
                    '${c.totalItems.value} templates',
                    style: GoogleFonts.poppins(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => Get.back(),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
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

class _Body extends StatelessWidget {
  final TemplateController c;
  final ScrollController scroll;
  final void Function(Template) onSelected;

  const _Body({
    required this.c,
    required this.scroll,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Zone 1: initial loader
      if (c.isLoading.value && c.templates.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      }

      // Zone 2: empty
      if (c.templates.isEmpty) {
        return SizedBox(
          height: 160,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.article_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'No templates found',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Zone 3: list + isolated footer
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: c.templates.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
              itemBuilder: (_, i) => _TemplateTile(
                key: ValueKey(c.templates[i].id),
                template: c.templates[i],
                onSelect: () {
                  onSelected(c.templates[i]);
                  Get.back();
                },
              ),
            ),
          ),

          // ── Footer: isolated Obx, never rebuilds the list ──
          Obx(() {
            if (c.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              );
            }
            if (!c.hasMore) {
              return Padding(
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
              );
            }
            return const SizedBox(height: 4);
          }),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Tile — zero Obx, plain StatefulWidget
// ─────────────────────────────────────────────────────────────

class _TemplateTile extends StatefulWidget {
  final Template template;
  final VoidCallback onSelect;

  const _TemplateTile({
    super.key,
    required this.template,
    required this.onSelect,
  });

  @override
  State<_TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<_TemplateTile> {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF8F8F8) : AppColors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMedia) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: MediaComponent(
                    type: GallertType.MessageFiles,
                    messageId: t.id?.toString() ?? '',
                    url: t.url!,
                    fileName: t.url!,
                    uploadType: 'server',
                    messageDirection: 'S',
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEF4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
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
                  const SizedBox(height: 5),
                  Text(
                    t.body ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: widget.onSelect,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }
}
