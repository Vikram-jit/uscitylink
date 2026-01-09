import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/widgets/typing_dots.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

enum TYPE { truck, driver }

class UserStatusTile extends StatefulWidget {
  final String name;
  final String id;
  final bool isOnline;
  final TYPE type;
  final bool isTyping;
  final int unreadCount;
  final String message;
  const UserStatusTile({
    super.key,
    required this.name,
    required this.isOnline,
    required this.id,
    this.type = TYPE.driver,
    this.isTyping = false,
    this.unreadCount = 0,
    this.message = "",
  });

  @override
  State<UserStatusTile> createState() => _UserStatusTileState();
}

class _UserStatusTileState extends State<UserStatusTile> {
  bool _isHovered = false;
  final controller = Get.find<HomeController>();

  // Username → Color Generator
  Color _generateColorFromName(String text) {
    final hash = text.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromARGB(255, r, g, b).withValues(alpha: 0.85);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isSelected = controller.selectedName.value == widget.name;
      final Color avatarColor = _generateColorFromName(widget.name);
      final String initial = widget.name.isNotEmpty
          ? widget.name[0].toUpperCase()
          : "?";

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),

        child: GestureDetector(
          onTap: () {
            controller.openDirectMessage(
              userId: widget.id,
              userName: widget.name,
            );
          },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : _isHovered
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                if (widget.isTyping) TypingDots(),
                if (!widget.isTyping)
                  Stack(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          initial,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (widget.type == TYPE.driver)
                        // Online Dot
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.isOnline
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.black,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(width: 6),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: widget.message.isEmpty ? 12 : 14,

                          fontWeight: isSelected
                              ? FontWeight.w600
                              : widget.message.isNotEmpty
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      if (widget.message.isNotEmpty)
                        Column(
                          children: [
                            SizedBox(height: 2),
                            Text(
                              widget.message,
                              maxLines: 1, // 🔥 THIS IS THE KEY
                              overflow: TextOverflow.ellipsis,
                              softWrap: false, // extra safety
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (widget.unreadCount > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          widget.unreadCount.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
