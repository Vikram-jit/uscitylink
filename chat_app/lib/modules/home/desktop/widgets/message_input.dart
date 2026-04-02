import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/models/message_response_model.dart' show Messages;
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/services/file_upload_service.dart';
import 'package:chat_app/core/services/socket_service.dart';
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
  PlatformFile? _pendingFile;

  final _focusNode = FocusNode();

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
      ignoring: widget.isPinMessage == 2, // 👉 disables all touch events

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
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
                  if (_pendingFile != null) _buildFilePreview(),
                  _buildTextField(),
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
          // Left accent bar
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7BE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Reply content
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

          // Dismiss button
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
    final file = _pendingFile!;
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
            onTap: () => setState(() => _pendingFile = null),
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
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(() {}),
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
            enabled: _msgCtrl.msgText.isNotEmpty || _pendingFile != null,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _msgCtrl.msgText.value.trim();
    if (text.isEmpty && _pendingFile == null) return;
    if (_pendingFile != null) {
      _openFilePreviewDialog();
    } else {
      _msgCtrl.sendMessage(
        body: text,
        userId: _msgCtrl.userProfile.value.id ?? '',
        replyMessageId: _msgCtrl.selectMessageReply.value?.id ?? "",
      );

      if (_msgCtrl.selectMessageReply.value != null) {
        _msgCtrl.selectMessageReply.value = null;
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
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      setState(() => _pendingFile = result.files.single);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.TOP);
    }
  }

  void _openFilePreviewDialog() {
    final file = _pendingFile;
    if (file == null) return;
    final captionCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: Get.context!,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A7BE0),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Send file',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: isSending
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Body
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
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
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Add a message',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: captionCtrl,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Optional caption...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF4A7BE0),
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSending
                            ? null
                            : () {
                                setState(() => _pendingFile = null);
                                Navigator.pop(context);
                              },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                final userId =
                                    _msgCtrl.userProfile.value.id ?? '';
                                if (userId.isEmpty) return;
                                setS(() => isSending = true);
                                final res = await FileUploadService()
                                    .uploadForUserMessage(
                                      file: file,
                                      userId: userId,
                                    );
                                if (!res.status || res.key == null) {
                                  setS(() => isSending = false);
                                  Get.snackbar(
                                    'Upload failed',
                                    res.message,
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }
                                SocketService().emit('send_message_to_user', {
                                  'body': captionCtrl.text.trim(),
                                  'userId': userId,
                                  'direction': 'S',
                                  'url': res.key,
                                  'thumbnail': res.thumbnail,
                                });
                                setState(() => _pendingFile = null);
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7BE0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send file',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  bool _caretHovered = false;

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

                // Text(
                //   'Send',
                //   style: TextStyle(
                //     fontSize: 13,
                //     fontWeight: FontWeight.w600,
                //     color: widget.enabled ? Colors.white : Colors.grey.shade500,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
