import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/desktop/widgets/media_gallery.dart';
import 'package:chat_app/modules/home/desktop/widgets/template_dialog.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupHeader extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final String status;

  const GroupHeader({
    super.key,
    this.userName = "",
    this.avatarUrl = "",
    this.status = "",
  });

  @override
  State<GroupHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<GroupHeader>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final messageController = Get.find<GroupMessageController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        messageController.switchTab(
          _tabController.index,
          MediaGallerySource.group,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          messageController: messageController,
          userName: widget.userName,
        ),
        _TabSection(tabController: _tabController),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GroupMessageController messageController;
  final String userName;

  const _TopBar({required this.messageController, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar + info — tappable
          GestureDetector(
            onTap: messageController.toggleDetails,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _GradientAvatar(messageController: messageController),
                const SizedBox(width: 12),
                _GroupInfo(
                  messageController: messageController,
                  userName: userName,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action buttons
          Row(children: [const SizedBox(width: 8), const _TemplateButton()]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient avatar
// ─────────────────────────────────────────────────────────────

class _GradientAvatar extends StatelessWidget {
  final GroupMessageController messageController;
  const _GradientAvatar({required this.messageController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final initial =
          messageController.group.value.name?.characters
              .take(1)
              .toString()
              .toUpperCase() ??
          '';
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.linkBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Group name + members
// ─────────────────────────────────────────────────────────────

class _GroupInfo extends StatelessWidget {
  final GroupMessageController messageController;
  final String userName;
  const _GroupInfo({required this.messageController, required this.userName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      child: Obx(() {
        final memberText = messageController.memmbers
            .map((f) {
              final username = f.userProfile?.username ?? '-';
              final driverNo = f.userProfile?.user?.driverNumber ?? '-';
              return '$username ($driverNo)';
            })
            .join(', ');

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageController.group.value.name ?? userName,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1730),
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF9B97A8),
                ),
                children: [
                  TextSpan(
                    text: '${messageController.memmbers.length} members  ·  ',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA07CE8),
                    ),
                  ),
                  TextSpan(text: memberText),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small icon button
// ─────────────────────────────────────────────────────────────

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF3EDFD) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF6C3FC4).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? AppColors.primary : const Color(0xFF9B97A8),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tab section
// ─────────────────────────────────────────────────────────────

class _TabSection extends StatelessWidget {
  final TabController tabController;
  const _TabSection({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: const Color(0xFF9B97A8),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.primary, width: 2.5),
          ),
        ),
        dividerColor: Colors.black12,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 15),
                SizedBox(width: 7),
                Text('Messages'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file_rounded, size: 15),
                SizedBox(width: 7),
                Text('Files'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.push_pin_outlined, size: 15),
                SizedBox(width: 7),
                Text('Pins'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Template button
// ─────────────────────────────────────────────────────────────

class _TemplateButton extends StatefulWidget {
  const _TemplateButton();

  @override
  State<_TemplateButton> createState() => _TemplateButtonState();
}

class _TemplateButtonState extends State<_TemplateButton> {
  bool _hovered = false;

  static const _purple = AppColors.primary;
  static const _purpleLight = AppColors.white;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => TemplateDialog.show(
          onSelected: (template) {
            final mc = Get.find<GroupMessageController>();
            mc.selectTemplateUrl(template);
            mc.msgInputController.text = template.body ?? '';
            // mc.setTemplateMessage(template);
          },
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? _purple : _purpleLight,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered ? _purple : _purple.withValues(alpha: 0.28),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: _purple.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 13,
                color: _hovered ? Colors.white : _purple,
              ),
              const SizedBox(width: 6),
              Text(
                'Templates',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : _purple,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
