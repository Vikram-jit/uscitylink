import 'package:chat_app/core/theme/colors.dart';
import 'package:flutter/material.dart';

class SidebarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final List<PopupMenuEntry> menuItems;

  // ✅ NEW
  final VoidCallback? onTap;

  const SidebarIcon(
    this.icon, {
    super.key,
    required this.tooltip,
    this.active = false,
    this.menuItems = const [],
    this.onTap,
  });

  @override
  State<SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<SidebarIcon> {
  bool _isHovered = false;

  void _openRightSideMenu(BuildContext context, Offset position) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      color: AppColors.white,
      position: RelativeRect.fromLTRB(
        position.dx + 20,
        position.dy - 20,
        overlay.size.width,
        overlay.size.height,
      ),
      items: widget.menuItems,
    );
  }

  void _handleTap(TapDownDetails details) {
    // 1️⃣ Menu has priority
    if (widget.menuItems.isNotEmpty) {
      _openRightSideMenu(context, details.globalPosition);
      return;
    }

    // 2️⃣ Custom tap
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    // 3️⃣ Fallback
    debugPrint(widget.tooltip);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _handleTap,
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
      ),
    );
  }
}
