import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/system_messages/system_message_controller.dart';
import 'package:chat_app/modules/system_messages/system_message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UnreadMessagesDialog extends StatelessWidget {
  const UnreadMessagesDialog({super.key});

  static String _fmt(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SystemMessageController>();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
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
                      Icons.notifications_active_outlined,
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
                          'Unread System Messages',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1730),
                          ),
                        ),
                        Text(
                          'Uncompleted messages must be marked one by one.',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF9B97A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mark All Read button
                  GestureDetector(
                    onTap: () async {
                      await c.markAllRead();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mark All Read',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF444441),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Message list ──
            Expanded(
              child: Obx(() {
                final msgs = List<SystemMessage>.from(c.unreadMessages);

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Color(0xFF27500A), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'All messages completed.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: const Color(0xFF9B97A8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.dmSans(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: msgs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    return _UnreadMessageRow(
                      msg: msg,
                      onAction: () async {
                        await c.markComplete(msg.id);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadMessageRow extends StatelessWidget {
  final SystemMessage msg;
  final VoidCallback onAction;

  const _UnreadMessageRow({required this.msg, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isCompleted = msg.isCompleted;
    final completedName = msg.completedByUser?.username ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      UnreadMessagesDialog._fmt(msg.messageTimestampUtc),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: const Color(0xFF9B97A8),
                      ),
                    ),
                    if (isCompleted && completedName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _CompletedChip(name: completedName),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  msg.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF1A1730),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFE8F0FE)
                    : const Color(0xFFEAF3DE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCompleted ? 'Mark Read' : 'Mark Completed',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFF27500A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedChip extends StatelessWidget {
  final String name;
  const _CompletedChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Completed by $name',
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF27500A),
        ),
      ),
    );
  }
}
