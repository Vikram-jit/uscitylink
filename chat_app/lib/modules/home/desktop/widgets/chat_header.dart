import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/desktop/widgets/template_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatHeader extends StatefulWidget {
  const ChatHeader({super.key});

  @override
  State<ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends State<ChatHeader>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mc = Get.find<MessageController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _mc.switchTab(_tabController.index);
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildTopBar(), _buildTabBar()],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      child: Row(
        children: [
          // ── Avatar + online dot ──
          Obx(() {
            final profile = _mc.userProfile.value;
            final isOnline = profile.isOnline ?? false;
            final initial = (profile.username?.isNotEmpty == true)
                ? profile.username![0].toUpperCase()
                : '?';
            final avatarColor = isOnline
                ? AppColors.avatarGreen
                : AppColors.avatarOrange;

            return Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.onlineGreen
                          : const Color(0xFFCCCCCC),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(width: 12),

          // ── User info ──
          Expanded(
            child: Obx(() {
              final profile = _mc.userProfile.value;
              final name = profile.username ?? '—';
              final driverNo = profile.user?.driverNumber ?? '—';
              final phone = profile.user?.phoneNumber ?? '—';
              final truck = _mc.truckNumber.value ?? '—';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + driver number
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          driverNo,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Phone + truck inline
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 11,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        phone,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.local_shipping_outlined,
                        size: 11,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          truck,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          const SizedBox(width: 8),

          // ── Template button ──
          _TemplateButton(),

          const SizedBox(width: 6),

          // ── More menu ──
          _HeaderIconBtn(icon: Icons.more_vert_rounded, onTap: () {}),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.secondaryText,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.primary, width: 2.5),
          ),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 14),
                SizedBox(width: 6),
                Text('Messages'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attach_file_rounded, size: 14),
                SizedBox(width: 6),
                Text('Files'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.push_pin_outlined, size: 14),
                SizedBox(width: 6),
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
  @override
  State<_TemplateButton> createState() => _TemplateButtonState();
}

class _TemplateButtonState extends State<_TemplateButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => TemplateDialog.show(
          onSelected: (template) {
            // Pass selected template to message controller
            final mc = Get.find<MessageController>();
            // mc.setTemplateMessage(template);
          },
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primary : const Color(0xFFF4EEF4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 14,
                color: _hovered ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Templates',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header icon button
// ─────────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  State<_HeaderIconBtn> createState() => _HeaderIconBtnState();
}

class _HeaderIconBtnState extends State<_HeaderIconBtn> {
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF4EEF4) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withOpacity(0.25)
                  : const Color(0xFFE8E8E8),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovered ? AppColors.primary : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
