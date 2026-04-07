import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupInput extends StatefulWidget {
  const GroupInput({super.key});

  @override
  State<GroupInput> createState() => _GroupInputState();
}

class _GroupInputState extends State<GroupInput> {
  final _c = Get.find<GroupMessageController>();

  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrike = false;
  bool _isFocused = false;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  TextStyle get _textStyle => GoogleFonts.poppins(
    color: Colors.black87,
    fontSize: 14,
    fontWeight: _isBold ? FontWeight.w600 : FontWeight.w400,
    fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
    decoration: _isStrike ? TextDecoration.lineThrough : TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Reply bar ──
          Obx(() {
            final reply = _c.selectMessageReply.value;
            if (reply == null) return const SizedBox.shrink();
            return _ReplyBar(
              reply: reply,
              senderName: reply.sender?.username ?? 'Unknown',
              onDismiss: () => _c.selectMessageReply.value = null,
            );
          }),

          // ── Input box ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
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
                if (_c.pendingFile != null) _buildFilePreview(),
                _buildTextField(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Toolbar ─────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          _iconBtn(
            Icons.attach_file_rounded,
            tooltip: 'Attach file',
            onTap: _pickFile,
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
          _iconBtn(Icons.code_rounded, tooltip: 'Code'),
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

  // ── File preview ─────────────────────────────────────────────

  Widget _buildFilePreview() {
    final file = _c.pendingFile!;
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
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _c.pendingFile = null),
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

  // ── Text field ───────────────────────────────────────────────

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
          // Typing indicator
          if (event.logicalKey != LogicalKeyboardKey.shift &&
              event.logicalKey != LogicalKeyboardKey.controlLeft &&
              event.logicalKey != LogicalKeyboardKey.controlRight &&
              event.logicalKey != LogicalKeyboardKey.metaLeft &&
              event.logicalKey != LogicalKeyboardKey.metaRight) {
            _c.onKeyPressed();
          }
        },
        child: TextFormField(
          focusNode: _focusNode,
          controller: _c.msgInputController,
          style: _textStyle,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            fillColor: Colors.white,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Message group…',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────

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
          Obx(
            () => _SendButton(
              enabled: _c.msgText.isNotEmpty || _c.pendingFile != null,
              onSend: _send,
            ),
          ),
        ],
      ),
    );
  }

  // ── Send logic ───────────────────────────────────────────────

  void _send() {
    final text = _c.msgText.value.trim();
    if (text.isEmpty && _c.pendingFile == null) return;

    if (_c.pendingFile != null) {
      _openFileSendDialog();
    } else {
      _c.sendMessage(
        body: text,
        replyMessageId: _c.selectMessageReply.value?.id,
      );
      _c.selectMessageReply.value = null;
    }
  }

  // ── File send dialog ─────────────────────────────────────────

  void _openFileSendDialog() {
    final file = _c.pendingFile;
    if (file == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        final captionCtrl = TextEditingController();
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
                            onTap: isSending ? null : () => Navigator.pop(ctx),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                      Text(
                                        '${(file.size / 1024).toStringAsFixed(1)} KB',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                            controller: _c.msgInputController,
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
                                  setState(() => _c.pendingFile = null);
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
                            final bool result = await _c.sendFile();

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

  // ── Helpers ──────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _c.pendingFile = result.files.single);
    } catch (e) {
      AppSnackbar.error(e.toString());
    }
  }

  void _insertEmoji() {
    final c = _c.msgInputController;
    final s = c.selection.start >= 0 ? c.selection.start : c.text.length;
    c.text = c.text.replaceRange(
      s,
      c.selection.end >= 0 ? c.selection.end : s,
      ' 🙂',
    );
    c.selection = TextSelection.collapsed(offset: s + 2);
    _c.msgText.value = c.text;
  }

  void _insertMention() {
    final c = _c.msgInputController;
    final s = c.selection.start >= 0 ? c.selection.start : c.text.length;
    c.text = c.text.replaceRange(
      s,
      c.selection.end >= 0 ? c.selection.end : s,
      '@',
    );
    c.selection = TextSelection.collapsed(offset: s + 1);
    _c.msgText.value = c.text;
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap, String? tooltip}) {
    Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
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
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF4A7BE0) : Colors.grey.shade600,
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  Widget _divider() => Container(
    width: 1,
    height: 18,
    color: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─────────────────────────────────────────────────────────────
// Reply bar
// ─────────────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final dynamic reply;
  final String senderName;
  final VoidCallback onDismiss;

  const _ReplyBar({
    required this.reply,
    required this.senderName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final preview = (reply.body?.isNotEmpty == true)
        ? reply.body!
        : reply.url ?? 'Attachment';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
              color: AppColors.primary,
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
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
}

// ─────────────────────────────────────────────────────────────
// Send button
// ─────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onSend;

  const _SendButton({required this.enabled, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          Icons.send_rounded,
          size: 14,
          color: enabled ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }
}
