import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/theme/text_styles.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChannelTile extends StatefulWidget {
  final String name;
  final bool active;
  final IconData icon;
  final SidebarViewType sidebarViewType;
  const ChannelTile(
    this.name, {
    super.key,
    this.active = false,
    this.icon = Icons.tag,
    required this.sidebarViewType,
  });

  @override
  State<ChannelTile> createState() => _ChannelTileState();
}

class _ChannelTileState extends State<ChannelTile> {
  bool _isHovered = false;
  HomeController controller = Get.find<HomeController>();
  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.active;

    return Obx(() {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            controller.currentView.value = widget.name == "Directories"
                ? SidebarViewType.directory
                : widget.sidebarViewType;
            controller.selectedName.value = widget.name;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,

            // 🎨 Background states
            decoration: BoxDecoration(
              color: controller.selectedName.value == widget.name
                  ? AppColors
                        .primary // active
                  : _isHovered
                  ? AppColors.primary.withValues(alpha: 0.10) // hover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),

            // 📏 Reduced tile spacing
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: controller.selectedName.value == widget.name
                      ? Colors.white
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.name,
                  style: TStyle.sidebarItem.copyWith(
                    color: controller.selectedName.value == widget.name
                        ? Colors.white
                        : AppColors.primary,
                    fontWeight: controller.selectedName.value == widget.name
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
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
