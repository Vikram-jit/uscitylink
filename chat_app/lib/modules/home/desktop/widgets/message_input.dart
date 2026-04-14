import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/core/widgets/local_media_preview.dart';
import 'package:chat_app/models/message_response_model.dart' show Messages;
import 'package:chat_app/modules/home/controllers/message_controller.dart';

import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageInput extends StatefulWidget {
  final int isPinMessage;

  const MessageInput({super.key, required this.isPinMessage});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _msgCtrl = Get.find<MessageController>();

  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrike = false;
  bool _isFocused = false;

  final _focusNode = FocusNode();

  // ScrollController to keep caret visible as content grows
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );

    // Auto-focus when reply is selected
    ever(_msgCtrl.selectMessageReply, (message) {
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TextStyle get _textStyle => GoogleFonts.inter(
    color: Colors.black87,
    fontSize: 14,
    fontWeight: _isBold ? FontWeight.w600 : FontWeight.w400,
    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
    decoration: _isStrike ? TextDecoration.lineThrough : TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.isPinMessage == 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            return _msgCtrl.selectTemplateUrl.value != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Align(
                              alignment: AlignmentGeometry.centerLeft,
                              child: Text(
                                "Selected Template:",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () {
                                _msgCtrl.selectTemplateUrl.value = null;
                                _msgCtrl.msgInputController.clear();
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MediaComponent(
                            isGalleryBool: false,
                            initialIndex: 0,
                            type: GallertType.MessageFiles,
                            messageId:
                                _msgCtrl.selectTemplateUrl.value?.id ?? "",
                            url: _msgCtrl.selectTemplateUrl.value?.url ?? "-",
                            fileName:
                                _msgCtrl.selectTemplateUrl.value?.url ?? '',
                            uploadType: 'server',
                            messageDirection: "S",
                            thumbnail: null,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();
          }),
          Obx(() {
            final reply = _msgCtrl.selectMessageReply.value;
            if (reply == null) return const SizedBox.shrink();
            return _buildReplyBar(reply);
          }),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFocused ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolbar(),
                  if (_msgCtrl.pendingFile != null) _buildFilePreview(),
                  _buildTextField(), // ✅ now height-constrained + scrollable
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(Messages reply) {
    final isMe = reply.messageDirection == 'R';
    final senderName = isMe
        ? (_msgCtrl.userProfile.value.username ?? 'You')
        : reply.sender?.username ?? 'Staff';

    final previewText = reply.body?.isNotEmpty == true
        ? reply.body!
        : reply.url ?? 'Attachment';

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7BE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Replying to $senderName',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A7BE0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _msgCtrl.selectMessageReply.value = null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          _iconBtn(
            Icons.attach_file_rounded,
            onTap: _pickFile,
            tooltip: 'Attach file',
          ),
          _divider(),
          _toggleBtn(
            Icons.format_bold,
            active: _isBold,
            tooltip: 'Bold',
            onTap: () => setState(() => _isBold = !_isBold),
          ),
          _toggleBtn(
            Icons.format_italic,
            active: _isItalic,
            tooltip: 'Italic',
            onTap: () => setState(() => _isItalic = !_isItalic),
          ),
          _toggleBtn(
            Icons.format_strikethrough,
            active: _isStrike,
            tooltip: 'Strikethrough',
            onTap: () => setState(() => _isStrike = !_isStrike),
          ),
          _divider(),
          _iconBtn(Icons.format_list_bulleted_rounded, tooltip: 'Bullet list'),
          _iconBtn(
            Icons.format_list_numbered_rounded,
            tooltip: 'Numbered list',
          ),
          _iconBtn(Icons.code_rounded, tooltip: 'Code block'),
          _divider(),
          _iconBtn(
            Icons.sentiment_satisfied_alt_outlined,
            tooltip: 'Emoji',
            onTap: _insertEmoji,
          ),
          _iconBtn(
            Icons.alternate_email_rounded,
            tooltip: 'Mention',
            onTap: _insertMention,
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final file = _msgCtrl.pendingFile!;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFA),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: Color(0xFF4A7BE0),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _msgCtrl.pendingFile = null),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Height-constrained text field with internal scrolling
  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 36, // single-line height
          maxHeight: 120, // ~5 lines — clamps growth, enables scroll
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            reverse: true, // keeps the latest line (caret) in view
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is! KeyDownEvent) return;
                final keys = HardwareKeyboard.instance.logicalKeysPressed;
                final isCtrl =
                    keys.contains(LogicalKeyboardKey.controlLeft) ||
                    keys.contains(LogicalKeyboardKey.controlRight) ||
                    keys.contains(LogicalKeyboardKey.metaLeft) ||
                    keys.contains(LogicalKeyboardKey.metaRight);
                if (event.logicalKey == LogicalKeyboardKey.enter && isCtrl) {
                  _send();
                }
              },
              child: TextFormField(
                focusNode: _focusNode,
                controller: _msgCtrl.msgInputController,
                style: _textStyle,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Message #general',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                maxLines: null, // unlimited lines inside the scroll area
                keyboardType: TextInputType.multiline,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: [
          Text(
            'Ctrl+Enter to send',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const Spacer(),
          _SendButton(
            enabled:
                _msgCtrl.msgText.isNotEmpty || _msgCtrl.pendingFile != null,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _msgCtrl.msgText.value.trim();
    if (text.isEmpty && _msgCtrl.pendingFile == null) return;
    if (_msgCtrl.pendingFile != null) {
      _openFilePreviewDialog();
    } else {
      _msgCtrl.sendMessage(
        body: text,
        userId: _msgCtrl.userProfile.value.id ?? '',
        replyMessageId: _msgCtrl.selectMessageReply.value?.id ?? "",
        url: _msgCtrl.selectTemplateUrl.value?.url ?? "",
      );

      if (_msgCtrl.selectMessageReply.value != null) {
        _msgCtrl.selectMessageReply.value = null;
      }
      if (_msgCtrl.selectTemplateUrl.value != null) {
        _msgCtrl.selectTemplateUrl.value = null;
      }
    }
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap, String? tooltip}) {
    Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip, child: btn);
    return btn;
  }

  Widget _toggleBtn(
    IconData icon, {
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8EDFA) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF4A7BE0) : Colors.grey.shade600,
        ),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip, child: btn);
    return btn;
  }

  Widget _divider() => Container(
    width: 1,
    height: 18,
    color: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  void _insertEmoji() {
    final c = _msgCtrl.msgInputController;
    final s = c.selection.start >= 0 ? c.selection.start : c.text.length;
    final newText = c.text.replaceRange(
      s,
      c.selection.end >= 0 ? c.selection.end : s,
      ' 🙂',
    );
    c.text = newText;
    c.selection = TextSelection.collapsed(offset: s + 2);
    _msgCtrl.msgText.value = c.text;
  }

  void _insertMention() {
    final c = _msgCtrl.msgInputController;
    final s = c.selection.start >= 0 ? c.selection.start : c.text.length;
    final newText = c.text.replaceRange(
      s,
      c.selection.end >= 0 ? c.selection.end : s,
      '@',
    );
    c.text = newText;
    c.selection = TextSelection.collapsed(offset: s + 1);
    _msgCtrl.msgText.value = c.text;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      _msgCtrl.pendingFile = result.files.single;
      _openFilePreviewDialog();
    } on PlatformException catch (e) {
      AppSnackbar.error('Unsupported operation: $e');
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  void _openFilePreviewDialog() {
    final file = _msgCtrl.pendingFile;
    if (file == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (_, setS) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            elevation: 12,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EDFA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Color(0xFF4A7BE0),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Send file',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: isSending
                                ? null
                                : () {
                                    _msgCtrl.pendingFile = null;
                                    Navigator.pop(ctx);
                                  },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFE8E8E8),
                                ),
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
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE8E8E8),
                  ),

                  // Body
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File info card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE8E8E8),
                              ),
                            ),
                            child: LocalMediaPreview(
                              platformFile: file,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Caption label
                          Text(
                            'ADD A MESSAGE',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            onChanged: (v) {
                              _msgCtrl.onKeyPressed();
                            },
                            controller: _msgCtrl.msgInputController,
                            maxLines: 3,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.primaryText,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Optional caption…',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF9E9E9E),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8E8E8),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8E8E8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE8E8E8),
                  ),

                  // Footer
                  Container(
                    color: const Color(0xFFF8F8F8),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSending
                              ? null
                              : () {
                                  setState(() => _msgCtrl.pendingFile = null);
                                  Navigator.pop(ctx);
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE8E8E8)),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.secondaryText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
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
                        ElevatedButton.icon(
                          onPressed: () async {
                            final bool result = await _msgCtrl.sendFile();

                            if (result) {
                              Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 15),
                          label: Text(
                            'Send file',
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
                              horizontal: 18,
                              vertical: 10,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onSend;
  const _SendButton({required this.enabled, required this.onSend});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? AppColors.primary : Colors.grey.shade300;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.enabled ? widget.onSend : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(7),
                right: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.send_rounded,
                  size: 14,
                  color: widget.enabled ? Colors.white : Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
