// lib/modules/template/views/dialogs/template_form_dialog.dart

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/controllers/template_controller.dart';
import 'package:chat_app/modules/home/models/template_model.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplateFormDialog extends StatefulWidget {
  final Template? template;
  final TemplateController controller;

  const TemplateFormDialog._({required this.controller, this.template});

  static void show(
    BuildContext context,
    TemplateController controller,
    Template? template,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) =>
          TemplateFormDialog._(controller: controller, template: template),
    );
  }

  @override
  State<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<TemplateFormDialog> {
  final _nameCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final bool _isEdit;

  PlatformFile? _pendingFile;
  bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.template != null;
    if (_isEdit) {
      _nameCtrl.text = widget.template!.name ?? '';
      _bodyCtrl.text = widget.template!.body ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _pendingFile = result.files.single);
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  void _removeFile() => setState(() => _pendingFile = null);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = _isEdit
        ? await widget.controller.updateTemplate(
            id: widget.template!.id.toString(),
            name: _nameCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            pendingFile: _pendingFile,
          )
        : await widget.controller.createTemplate(
            name: _nameCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            pendingFile: _pendingFile,
          );

    if (ok) {
      // ── Close dialog first, then show snackbar ──
      Get.back();
      // Small delay so the dialog is fully gone before snackbar renders
      await Future.delayed(const Duration(milliseconds: 300));
      AppSnackbar.success(
        _isEdit
            ? 'Template updated successfully.'
            : 'Template created successfully.',
      );
    }
    // Err
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
              _buildFields(),
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
              color: const Color(0xFFF4EEF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isEdit ? Icons.edit_outlined : Icons.add_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEdit ? 'Edit Template' : 'New Template',
              style: GoogleFonts.poppins(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => Get.back(),
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

  // ── Fields ──────────────────────────────────────────────────

  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _FieldLabel('Title'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
            decoration: _inputDeco('Template title'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),

          const SizedBox(height: 16),

          // Body
          _FieldLabel('Body'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bodyCtrl,
            maxLines: 4,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
            decoration: _inputDeco('Template body message…'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Body is required' : null,
          ),

          const SizedBox(height: 16),

          // Attachment
          _FieldLabel('Attachment'),
          const SizedBox(height: 8),
          _buildAttachmentSection(),
        ],
      ),
    );
  }

  // ── Attachment section ──────────────────────────────────────

  Widget _buildAttachmentSection() {
    // Show existing attachment from edit mode
    final existingUrl = widget.template?.url;
    final hasExisting =
        existingUrl != null && existingUrl.isNotEmpty && _pendingFile == null;

    if (_pendingFile != null) {
      return _PendingFilePreview(
        file: _pendingFile!,
        isImage: _isImage(_pendingFile!.name),
        onRemove: _removeFile,
        onReplace: _pickFile,
      );
    }

    if (hasExisting) {
      return _ExistingFilePreview(url: existingUrl!, onReplace: _pickFile);
    }

    // Empty state — pick button
    return _PickerButton(onTap: _pickFile);
  }

  // ── Footer ──────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE8E8E8)),
              backgroundColor: Colors.white,
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
          Obx(
            () => ElevatedButton.icon(
              onPressed: widget.controller.isSaving.value ? null : _submit,
              icon: widget.controller.isSaving.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 15,
                    ),
              label: Text(
                _isEdit ? 'Save changes' : 'Create',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFE8E8E8),
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(
      color: const Color(0xFF9E9E9E),
      fontSize: 13,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Picker button — empty state
// ─────────────────────────────────────────────────────────────

class _PickerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PickerButton({required this.onTap});

  @override
  State<_PickerButton> createState() => _PickerButtonState();
}

class _PickerButtonState extends State<_PickerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF4EEF4) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withOpacity(0.4)
                  : const Color(0xFFE8E8E8),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 28,
                color: _hovered ? AppColors.primary : const Color(0xFFCCCCCC),
              ),
              const SizedBox(height: 6),
              Text(
                'Click to select a file',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? AppColors.primary : const Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Images, PDF, documents supported',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFBBBBBB),
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
// Pending file preview (newly selected, not yet uploaded)
// ─────────────────────────────────────────────────────────────

class _PendingFilePreview extends StatelessWidget {
  final PlatformFile file;
  final bool isImage;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _PendingFilePreview({
    required this.file,
    required this.isImage,
    required this.onRemove,
    required this.onReplace,
  });

  String get _sizeLabel {
    final kb = (file.size / 1024).toStringAsFixed(1);
    final mb = (file.size / (1024 * 1024)).toStringAsFixed(1);
    return file.size > 1024 * 1024 ? '$mb MB' : '$kb KB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: isImage && file.bytes != null
                  ? Image.memory(file.bytes!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFEEEEEE),
                      child: Icon(
                        _fileIcon(file.name),
                        size: 24,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ready to upload',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _sizeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Replace
          _SmallBtn(
            icon: Icons.swap_horiz_rounded,
            label: 'Replace',
            color: AppColors.linkBlue,
            onTap: onReplace,
          ),
          const SizedBox(width: 6),

          // Remove
          _SmallBtn(
            icon: Icons.close_rounded,
            label: 'Remove',
            color: const Color(0xFFE53935),
            onTap: onRemove,
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.videocam_rounded;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Icons.audiotrack_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

// ─────────────────────────────────────────────────────────────
// Existing file preview (from server, edit mode)
// ─────────────────────────────────────────────────────────────

class _ExistingFilePreview extends StatelessWidget {
  final String url;
  final VoidCallback onReplace;

  const _ExistingFilePreview({required this.url, required this.onReplace});

  bool get _isImage {
    final ext = url.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  String get _fileName => url.split('/').last;

  @override
  Widget build(BuildContext context) {
    final fullUrl = 'https://ciity-sms.s3.us-west-1.amazonaws.com/$url';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _isImage
                  ? Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 22,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFEEEEEE),
                      child: const Icon(
                        Icons.insert_drive_file_rounded,
                        size: 24,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEF4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Current attachment',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Replace
          _SmallBtn(
            icon: Icons.swap_horiz_rounded,
            label: 'Replace',
            color: AppColors.linkBlue,
            onTap: onReplace,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small labelled button
// ─────────────────────────────────────────────────────────────

class _SmallBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SmallBtn> createState() => _SmallBtnState();
}

class _SmallBtnState extends State<_SmallBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.3)
                  : const Color(0xFFE8E8E8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: widget.color),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
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
// Field label
// ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        color: AppColors.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}
