import 'dart:convert';

import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/desktop/widgets/reply_preview.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatefulWidget {
  final String name;
  final String time;
  final String message;
  final bool isMe;
  final String driverNumber;
  final String? mediaUrl;
  final String? mediaName;
  final String? uploadType;
  final String? thumbnail;
  final String id;
  final Messages? replyMessage;
  final String staffPin;

  // Action callbacks
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  MessageBubble({
    super.key,
    required this.id,
    required this.name,
    required this.time,
    required this.message,
    required this.driverNumber,
    required this.staffPin,
    this.isMe = false,
    this.mediaUrl,
    this.mediaName,
    this.uploadType,
    this.thumbnail,
    this.onReply,
    this.onForward,
    this.onPin,
    this.onDelete,
    this.replyMessage,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.grey.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? AppColors.avatarGreen
                          : AppColors.avatarOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: widget.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: " ",
                                    style: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                  TextSpan(
                                    text: widget.isMe
                                        ? "(${widget.driverNumber})"
                                        : "(staff)",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.time,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            if (widget.staffPin == "1") ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.push_pin_rounded,
                                size: 13,
                                color: Colors.amber,
                              ),
                            ],
                          ],
                        ),
                        if (widget.replyMessage != null) ...[
                          const SizedBox(height: 4),
                          ReplyPreview(replyMessage: widget.replyMessage!),
                          const SizedBox(height: 4),
                        ],
                        if (widget.message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          SelectableLinkify(
                            text: widget.message,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            linkStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            onOpen: (link) async {
                              final uri = Uri.parse(link.url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        ],

                        if (widget.mediaUrl != null) ...[
                          const SizedBox(height: 6),
                          MediaComponent(
                            initialIndex: 0,
                            type: GallertType.MessageFiles,
                            messageId: widget.id,
                            url: widget.mediaUrl!,
                            fileName: widget.mediaName ?? '',
                            uploadType: widget.uploadType ?? 'server',
                            messageDirection: widget.isMe ? 'S' : 'R',
                            thumbnail: widget.thumbnail,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Hover action bar
            if (_isHovered)
              Positioned(
                top: -18,
                right: 8,
                child: _ActionBar(
                  onReply: widget.onReply,
                  onForward: widget.onForward,
                  onPin: widget.onPin,
                  onDelete: widget.onDelete,
                  wPin: widget.staffPin.isNotEmpty
                      ? widget.staffPin == "1"
                            ? true
                            : false
                      : false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;
  final bool wPin;

  const _ActionBar({
    this.onReply,
    this.onForward,
    this.onPin,
    this.onDelete,
    this.wPin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.reply_rounded,
            tooltip: 'Reply',
            onTap: onReply,
          ),
          _ActionButton(
            icon: Icons.forward_rounded,
            tooltip: 'Forward',
            onTap: onForward,
          ),
          _ActionButton(
            icon: Icons.push_pin_outlined,
            tooltip: wPin ? 'Unpin' : 'Pin',
            onTap: onPin,
            isDanger: wPin,
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete',
            onTap: onDelete,
            isDanger: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isDanger;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isDanger = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isDanger
                        ? Colors.red.shade50
                        : Colors.grey.shade100)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered
                  ? (widget.isDanger ? Colors.red.shade700 : Colors.black87)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
