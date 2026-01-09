import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:chat_app/widgets/media_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final String name;
  final String time;
  final String message;
  final bool isMe;
  final String driverNumber;

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
    required this.driverNumber,
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
                    RichText(
                      text: TextSpan(
                        text: name,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: " ",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: isMe ? "($driverNumber)" : "(staff)",
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
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SelectableLinkify(
                    text: message,
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
