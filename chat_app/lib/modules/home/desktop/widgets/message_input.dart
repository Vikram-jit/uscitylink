import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(6.0),

          // bottomLeft and bottomRight remain square by default
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Shrink to fit content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The Text Input Area
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: TextField(
                style: GoogleFonts.poppins(
                  color: Colors.black, // Change this to your desired color
                  fontSize: 16,
                ),

                // 2. Controls the blinking cursor color
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true, // <--- Enable background color
                  fillColor: Colors.white, // <--- Set color to white
                  hintText: "Start a new message",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  border: InputBorder.none, // Remove default underline
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null, // Allows text to wrap nicely
                keyboardType: TextInputType.multiline,
              ),
            ),

            // 2. The Bottom Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  // -- Left Group --
                  // Plus Button (Circle)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Formatting Icon (Aa)
                  _buildIcon(Icons.text_format),

                  // Emoji Icon
                  _buildIcon(Icons.sentiment_satisfied_alt_outlined),

                  // Mention Icon (@)
                  _buildIcon(Icons.alternate_email),

                  // Vertical Divider
                  _buildDivider(),

                  // -- Middle Group --
                  // Video Icon
                  _buildIcon(Icons.videocam_outlined),

                  // Mic Icon
                  _buildIcon(Icons.mic_none_outlined),

                  // Vertical Divider
                  _buildDivider(),

                  // Edit/Note Icon
                  _buildIcon(Icons.edit_note),

                  // -- Spacer pushes the Send button to the right --
                  const Spacer(),

                  // -- Right Group (Send) --
                  Icon(Icons.send, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 4),
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

  // Helper widget to reduce code repetition for standard icons
  Widget _buildIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Icon(icon, color: Colors.grey.shade600, size: 22),
    );
  }

  // Helper widget for the vertical separators
  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade300,
    );
  }
}
