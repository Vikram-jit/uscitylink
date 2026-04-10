import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Changed to StatefulWidget — guards against rendering after dispose
class BroadcastList extends StatefulWidget {
  const BroadcastList({super.key});

  @override
  State<BroadcastList> createState() => _BroadcastListState();
}

class _BroadcastListState extends State<BroadcastList> {
  // ✅ Lazy getter — never captured at construction time
  BroadcastController get _c => Get.find<BroadcastController>();

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDetailDialog(dynamic item) {
    // ✅ mounted check — prevents dialog opening on a disposed view
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _BroadcastDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Broadcast List',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1730),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── List ──
          Expanded(
            // ✅ Obx is scoped tightly — reads _c inside build only
            child: Obx(() {
              final c = _c;

              if (c.isLoading.value && c.broadcasts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return ListView.builder(
                controller: c.scrollController,
                itemCount: c.broadcasts.length + (c.hasMore.value ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index == c.broadcasts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  final item = c.broadcasts[index];
                  final isSent = item.totalMessages == item.sentMessages;

                  return _BroadcastCard(
                    item: item,
                    isSent: isSent,
                    onDetail: () => _showDetailDialog(item),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Broadcast card row
// ─────────────────────────────────────────────────────────────

class _BroadcastCard extends StatelessWidget {
  final dynamic item;
  final bool isSent;
  final VoidCallback onDetail;

  const _BroadcastCard({
    required this.item,
    required this.isSent,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.body?.isNotEmpty == true ? item.body : '(media)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1730),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.totalMessages} total · ${item.sentMessages} sent',
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    color: const Color(0xFF9B97A8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          _StatusChip(isSent: isSent),
          const SizedBox(width: 8),

          Text(
            _BroadcastListState.formatDate(item.createdAt),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF9B97A8),
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: onDetail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFC),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Detail',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isSent;
  const _StatusChip({required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isSent ? const Color(0xFFEAF3DE) : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSent ? 'Sent' : 'Processing',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSent ? const Color(0xFF27500A) : const Color(0xFF633806),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail dialog — pure StatelessWidget, no controller references
// ─────────────────────────────────────────────────────────────

class _BroadcastDetailDialog extends StatelessWidget {
  final dynamic item;
  const _BroadcastDetailDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final messages = (item.broadcastMessages ?? []) as List;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EBFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Broadcast Details',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1730),
                          ),
                        ),
                        Text(
                          '${messages.length} recipient${messages.length == 1 ? '' : 's'}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF9B97A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Color(0xFF9B97A8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Table header
            Container(
              color: const Color(0xFFF8F8F8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Row(
                children: [
                  _ColHeader('Name', flex: 3),
                  _ColHeader('Phone', flex: 2),
                  _ColHeader('Driver No.', flex: 2),
                  _ColHeader('Status', flex: 2),
                  _ColHeader('Message', flex: 3),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Rows
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No recipients found',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: const Color(0xFF9B97A8),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F2F2),
                      ),
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final profile = msg.userProfile;
                        final user = profile?.user;

                        final name = profile?.username ?? '—';
                        final phone = user?.phoneNumber ?? '—';
                        final driverNo = user?.driverNumber ?? '—';
                        final status = msg.status ?? '—';
                        final body = msg.body?.isNotEmpty == true
                            ? msg.body
                            : '(media)';

                        return Container(
                          color: i.isEven
                              ? Colors.white
                              : const Color(0xFFFAFAF9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    _InitialsAvatar(name: name),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1A1730),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  phone,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF5A5670),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  driverNo,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF5A5670),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _MessageStatusChip(status: status),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  body,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.5,
                                    color: const Color(0xFF5A5670),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Footer
            Container(
              color: const Color(0xFFF8F8F8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _BroadcastListState.formatDate(item.createdAt),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9B97A8),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9B97A8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBFC),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MessageStatusChip extends StatelessWidget {
  final String status;
  const _MessageStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = switch (status.toLowerCase()) {
      'sent' => (const Color(0xFFEAF3DE), const Color(0xFF27500A)),
      'pending' => (const Color(0xFFFAEEDA), const Color(0xFF633806)),
      'failed' => (const Color(0xFFFCEBEB), const Color(0xFF791F1F)),
      _ => (const Color(0xFFF1EFE8), const Color(0xFF444441)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
