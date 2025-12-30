import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class UserStatusTile extends StatefulWidget {
  final String name;
  final bool isOnline;

  const UserStatusTile({super.key, required this.name, required this.isOnline});

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
            controller.currentView.value = SidebarViewType.directMessage;
            controller.selectedName.value = widget.name;
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
              children: [
                // Avatar
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

                    // Online Dot
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.isOnline ? Colors.green : Colors.grey,
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
                // Username
                Expanded(
                  child: Text(
                    widget.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.primary,
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
