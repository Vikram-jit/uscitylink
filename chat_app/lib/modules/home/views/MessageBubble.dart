import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final String name;
  final String time;
  final String message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.name,
    required this.time,
    required this.message,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Time Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                // First letter in a circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.avatarGreen
                        : AppColors.avatarOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Time
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Name
              ],
            ),
          ),

          // Message Box

          // Optional actions (Reply, Share)
        ],
      ),
    );
  }
}
