import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:chat_app/widgets/media_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final String name;
  final String time;
  final String message;
  final bool isMe;

  // Media
  final String? mediaUrl;
  final String? mediaName;
  final String? uploadType;
  final String? thumbnail;

  const MessageBubble({
    super.key,
    required this.name,
    required this.time,
    required this.message,
    this.isMe = false,
    this.mediaUrl,
    this.mediaName,
    this.uploadType,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isMe ? AppColors.avatarGreen : AppColors.avatarOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                // Name + Time
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],

                if (mediaUrl != null) ...[
                  const SizedBox(height: 6),
                  MediaComponent(
                    url: mediaUrl!,
                    fileName: mediaName ?? '',
                    uploadType: uploadType ?? 'server',
                    messageDirection: isMe ? 'S' : 'R',
                    thumbnail: thumbnail,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
