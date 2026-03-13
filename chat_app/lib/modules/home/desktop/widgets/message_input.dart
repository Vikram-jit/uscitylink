import 'package:chat_app/core/theme/colors.dart';
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
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final messageController = Get.find<MessageController>();

  double _fontSize = 16;
  bool _isBold = false;
  PlatformFile? _pendingFile;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      color: Colors.black,
      fontSize: _fontSize,
      fontWeight: _isBold ? FontWeight.w600 : FontWeight.w400,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(6.0)),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editor toolbar (Slack-like)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Attachment button
                  InkWell(
                    onTap: () {
                      _pickFile();
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: Colors.grey.shade700,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bold toggle
                  _toolbarToggle(
                    icon: Icons.format_bold,
                    isActive: _isBold,
                    onTap: () {
                      setState(() {
                        _isBold = !_isBold;
                      });
                    },
                  ),

                  // Font size dropdown
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<double>(
                      value: _fontSize,
                      underline: const SizedBox.shrink(),
                      iconSize: 18,
                      borderRadius: BorderRadius.circular(8),
                      items: const [
                        DropdownMenuItem(value: 14, child: Text("14")),
                        DropdownMenuItem(value: 16, child: Text("16")),
                        DropdownMenuItem(value: 18, child: Text("18")),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _fontSize = v;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 8),
                  _toolbarIcon(
                    Icons.sentiment_satisfied_alt_outlined,
                    onTap: _insertEmoji,
                  ),
                  _toolbarIcon(Icons.alternate_email, onTap: _insertMention),

                  const Spacer(),

                  // // Voice / video quick actions (hooks ready)
                  // _toolbarIcon(
                  //   Icons.videocam_outlined,
                  //   onTap: () {
                  //     Get.snackbar(
                  //       "Video",
                  //       "Video call not implemented yet.",
                  //       snackPosition: SnackPosition.TOP,
                  //     );
                  //   },
                  // ),
                  // _toolbarIcon(
                  //   Icons.mic_none_outlined,
                  //   onTap: () {
                  //     Get.snackbar(
                  //       "Voice",
                  //       "Voice recording not implemented yet.",
                  //       snackPosition: SnackPosition.TOP,
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),

            // Text input area
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is! KeyDownEvent) return;

                  final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
                  final pressedKeys =
                      HardwareKeyboard.instance.logicalKeysPressed;
                  final isCtrlOrCmd =
                      pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
                      pressedKeys.contains(LogicalKeyboardKey.controlRight) ||
                      pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
                      pressedKeys.contains(LogicalKeyboardKey.metaRight);

                  if (isEnter && isCtrlOrCmd) {
                    messageController.sendMessage(
                      body: messageController.msgText.value,
                      userId: messageController.userProfile.value.id ?? "",
                    );
                    return;
                  }

                  // Ignore modifier-only presses
                  if (event.logicalKey == LogicalKeyboardKey.shift ||
                      event.logicalKey == LogicalKeyboardKey.controlLeft ||
                      event.logicalKey == LogicalKeyboardKey.controlRight ||
                      event.logicalKey == LogicalKeyboardKey.metaLeft ||
                      event.logicalKey == LogicalKeyboardKey.metaRight) {
                    return;
                  }

                  messageController.onKeyPressed();
                },
                child: TextFormField(
                  controller: messageController.msgInputController,
                  style: textStyle,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Start a new message",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),

            // Bottom row with send button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Obx(() {
                    final hasText = messageController.msgText.isNotEmpty;

                    return ElevatedButton.icon(
                      onPressed: hasText
                          ? () {
                              messageController.sendMessage(
                                body: messageController.msgText.value,
                                userId:
                                    messageController.userProfile.value.id ??
                                    "",
                              );
                              messageController.msgText.value = "";
                            }
                          : null,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text("Send"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, {VoidCallback? onTap}) {
    final iconWidget = Icon(icon, color: Colors.grey.shade600, size: 20);

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: iconWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(padding: const EdgeInsets.all(2.0), child: iconWidget),
      ),
    );
  }

  Widget _toolbarToggle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : Colors.grey.shade700,
          size: 18,
        ),
      ),
    );
  }

  void _insertEmoji() {
    final controller = messageController.msgInputController;
    final text = controller.text;
    final selection = controller.selection;
    const emoji = " 🙂";

    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, emoji);
    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: start + emoji.length),
    );
    messageController.msgText.value = controller.text.trim();
  }

  void _insertMention() {
    final controller = messageController.msgInputController;
    final text = controller.text;
    final selection = controller.selection;
    const mention = "@";

    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, mention);
    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: start + mention.length),
    );
    messageController.msgText.value = controller.text.trim();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        // On web we must request bytes, mobile/desktop can use path
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) {
        return; // user cancelled
      }

      _pendingFile = result.files.single;
      _openFilePreviewDialog();
    } catch (e) {
      Get.snackbar(
        "File picker error",
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showAttachmentNotSupported() {
    Get.snackbar(
      "Attachments not available",
      "File attachments are only supported on native (dart:io) builds, not on web.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
    );
  }

  void _openFilePreviewDialog() {
    final file = _pendingFile;
    if (file == null) return;

    final captionController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: Get.context!,
      barrierDismissible: !isSending,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                  maxHeight: 420,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attachment,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Review attachment",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSending
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${(file.size / 1024).toStringAsFixed(1)} KB",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Caption (optional)",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: captionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Add a caption...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
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
                                    _pendingFile = null;
                                    Navigator.of(context).pop();
                                  },
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    final userId =
                                        messageController
                                            .userProfile
                                            .value
                                            .id ??
                                        "";
                                    if (userId.isEmpty) {
                                      Get.snackbar(
                                        "Error",
                                        "User not selected.",
                                        snackPosition: SnackPosition.TOP,
                                      );
                                      return;
                                    }
                                    setState(() {
                                      isSending = true;
                                    });
                                    final uploadService = FileUploadService();
                                    final result = await uploadService
                                        .uploadForUserMessage(
                                          file: file,
                                          userId: userId,
                                        );

                                    if (!result.status || result.key == null) {
                                      setState(() {
                                        isSending = false;
                                      });
                                      Get.snackbar(
                                        "Upload failed",
                                        result.message,
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final caption = captionController.text
                                        .trim();

                                    SocketService()
                                        .emit('send_message_to_user', {
                                          'body': caption,
                                          'userId': userId,
                                          'direction': 'S',
                                          'url': result.key,
                                          'thumbnail': result.thumbnail,
                                        });

                                    _pendingFile = null;
                                    captionController.dispose();
                                    Navigator.of(context).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: isSending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text("Send"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
