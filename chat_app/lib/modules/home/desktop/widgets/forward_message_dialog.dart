import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/models/message_response_model.dart';
import 'package:chat_app/modules/home/controllers/forward_message_controller.dart';
import 'package:chat_app/modules/home/models/channel_memmber_model.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ── Slack light palette ──
const _white = Colors.white;
const _pageBg = Color(0xFFF8F8F8);
const _border = Color(0xFFE8E8E8);
const _text1 = Color(0xFF1D1C1D);
const _text2 = Color(0xFF616061);
const _textMuted = Color(0xFF9E9E9E);
const _purple = Color(0xFF4A154B);
const _purpleBg = Color(0xFFF4EEF4);
const _green = Color(0xFF2BAC76);
const _blue = Color(0xFF1264A3);
const _amber = Color(0xFFFFBF00);

class ForwardMessageDialog extends StatefulWidget {
  final Messages message;
  const ForwardMessageDialog({super.key, required this.message});

  static void show(Messages message) {
    if (!Get.isRegistered<ForwardMessageController>(tag: 'forward')) {
      Get.put(Get.find<ForwardMessageController>(), tag: 'forward');
    }
    Get.find<ForwardMessageController>(
      tag: 'forward',
    ).fetchUsers(refresh: true);
    Get.dialog(
      ForwardMessageDialog(message: message),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
    );
  }

  @override
  State<ForwardMessageDialog> createState() => _ForwardMessageDialogState();
}

class _ForwardMessageDialogState extends State<ForwardMessageDialog> {
  final ForwardMessageController _c = Get.find<ForwardMessageController>(
    tag: 'forward',
  );
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search.text = _c.searchText.value;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_c.isLoadingMore.value &&
        _c.hasMore.value) {
      _c.fetchUsers();
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return DateFormat('MMM d  h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _border),
      ),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const _D(),
              _buildMessageSection(),
              const _D(),
              _buildSearchSection(),
              Obx(
                () => _c.selectedUserIds.isEmpty
                    ? const SizedBox(height: 2)
                    : _SelectedBar(count: _c.selectedUserIds.length),
              ),
              Flexible(
                child: _UserList(scroll: _scroll, c: _c),
              ),
              const _D(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Forward message',
              style: GoogleFonts.poppins(
                color: _text1,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          _IconBtn(
            icon: Icons.close_rounded,
            onTap: () {
              _c.reset();
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  // ── Message preview ─────────────────────────────────────────

  Widget _buildMessageSection() {
    final msg = widget.message;
    final isStaff = msg.messageDirection == 'S';
    final sender = isStaff
        ? (msg.sender?.username ?? 'Staff')
        : (msg.sender?.username ?? 'Driver');
    final sub = isStaff ? 'staff' : (msg.sender?.user?.driverNumber ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Message'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            constraints: const BoxConstraints(maxHeight: 110),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: _amber),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      sender,
                                      style: GoogleFonts.poppins(
                                        color: _text1,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (sub.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _purpleBg,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          sub,
                                          style: GoogleFonts.poppins(
                                            color: _purple,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatDate(msg.messageTimestampUtc),
                                  style: GoogleFonts.poppins(
                                    color: _textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (msg.url != null && msg.url!.isNotEmpty) ...[
                              MediaComponent(
                                messageId: msg.id ?? '',
                                url: msg.url!,
                                fileName: msg.url ?? '',
                                uploadType: msg.urlUploadType ?? 'server',
                                messageDirection: msg.messageDirection ?? 'S',
                                thumbnail: msg.thumbnail,
                                type: GallertType.MessageFiles,
                              ),
                              if (msg.body != null && msg.body!.isNotEmpty)
                                const SizedBox(height: 4),
                            ],
                            if (msg.body != null && msg.body!.isNotEmpty)
                              Text(
                                msg.body!,
                                style: GoogleFonts.poppins(
                                  color: _text2,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ───────────────────────────────────────────────────

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Send to'),
          const SizedBox(height: 6),
          Obx(
            () => TextField(
              controller: _search,
              style: GoogleFonts.poppins(color: _text1, fontSize: 13),
              onChanged: (v) => _c.searchText.value = v,
              decoration: InputDecoration(
                hintText: 'Search by name or vehicle…',
                hintStyle: GoogleFonts.poppins(color: _textMuted, fontSize: 13),
                filled: true,
                fillColor: _white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _textMuted,
                  size: 18,
                ),
                suffixIcon: _TruckToggle(
                  active: _c.isTruckMode.value,
                  onTap: () {
                    _c.toggleTruckMode();
                    if (!_c.isTruckMode.value) _search.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _purple, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          // Cancel
          OutlinedButton(
            onPressed: () {
              _c.reset();
              Get.back();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              backgroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: _text2,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Send
          Expanded(
            child: Obx(() {
              final count = _c.selectedUserIds.length;
              final enabled = count > 0;
              return ElevatedButton.icon(
                onPressed: enabled
                    ? () => _c.sendForward(widget.message)
                    : null,
                icon: Icon(
                  Icons.send_rounded,
                  size: 15,
                  color: enabled ? _white : _textMuted,
                ),
                label: Text(
                  enabled ? 'Send to $count drivers' : 'Send',
                  style: GoogleFonts.poppins(
                    color: enabled ? _white : _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  disabledBackgroundColor: _border,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Selected bar
// ─────────────────────────────────────────────────────────────

class _SelectedBar extends StatelessWidget {
  final int count;
  const _SelectedBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: _green),
          const SizedBox(width: 5),
          Text(
            '$count people selected',
            style: GoogleFonts.poppins(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.find<ForwardMessageController>(
              tag: 'forward',
            ).selectedUserIds.clear(),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User list
// ─────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final ScrollController scroll;
  final ForwardMessageController c;
  const _UserList({required this.scroll, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoading.value && c.users.isEmpty) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _purple),
          ),
        );
      }

      if (c.users.isEmpty) {
        return SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  color: _textMuted,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  'No drivers found',
                  style: GoogleFonts.poppins(color: _textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        controller: scroll,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        itemCount: c.users.length + (c.isLoadingMore.value ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == c.users.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _purple,
                ),
              ),
            );
          }
          return _UserTile(user: c.users[i], c: c);
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// User tile
// ─────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserChannels user;
  final ForwardMessageController c;
  const _UserTile({required this.user, required this.c});

  @override
  Widget build(BuildContext context) {
    final name = user.userProfile?.username ?? 'Unknown';
    final vehicle = user.assginTrucks ?? 'Not assigned';
    final userId = user.userProfileId ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarColor = (user.userProfile?.id?.hashCode ?? 0).isEven
        ? AppColors.avatarGreen
        : AppColors.avatarOrange;

    return GestureDetector(
      onTap: () => c.toggleUser(userId),
      child: Obx(() {
        final selected = c.isSelected(userId);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _purpleBg : _white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? _purple.withOpacity(0.35) : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? _purple : avatarColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: _white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name + vehicle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: _text1,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_rounded,
                          size: 11,
                          color: _text2,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            vehicle,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: _text2,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? _purple : _white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected ? _purple : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 13, color: _white)
                    : null,
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        color: _text2,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _TruckToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _TruckToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _purple : _pageBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? _purple : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_rounded,
              size: 13,
              color: active ? _white : _text2,
            ),
            const SizedBox(width: 4),
            Text(
              'Truck',
              style: GoogleFonts.poppins(
                color: active ? _white : _text2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _text2, size: 16),
        ),
      ),
    );
  }
}

class _D extends StatelessWidget {
  const _D();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _border);
}
