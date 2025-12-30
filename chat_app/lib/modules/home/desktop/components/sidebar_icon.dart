import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class SidebarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final List<PopupMenuEntry> menuItems;

  const SidebarIcon(
    this.icon, {
    super.key,
    required this.tooltip,
    this.active = false,
    this.menuItems = const [],
  });

  @override
  _SidebarIconState createState() => _SidebarIconState();
}

class _SidebarIconState extends State<SidebarIcon> {
  bool _isHovered = false; // 👈 track hover state

  void _openRightSideMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      color: AppColors.white,
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 20,
        position.dy - 20,
        overlay.size.width,
        overlay.size.height,
      ),
      items: widget.menuItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),

      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          if (widget.menuItems.isNotEmpty) {
            _openRightSideMenu(context, details.globalPosition);
          }
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),

          child: AnimatedScale(
            scale: _isHovered ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.active ? AppColors.primary : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
