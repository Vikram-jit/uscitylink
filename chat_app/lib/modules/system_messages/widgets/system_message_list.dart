import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/system_messages/system_message_controller.dart';
import 'package:chat_app/modules/system_messages/system_message_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SystemMessageList extends StatefulWidget {
  const SystemMessageList({super.key});

  @override
  State<SystemMessageList> createState() => _SystemMessageListState();
}

class _SystemMessageListState extends State<SystemMessageList> {
  SystemMessageController get _c => Get.find<SystemMessageController>();

  static String _fmt(String? raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'System Messages',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1730),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Column headers ──
          Container(
            color: const Color(0xFFF8F8F8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                _ColHeader('#', flex: 1),
                _ColHeader('Message', flex: 5),
                _ColHeader('Completed By', flex: 3),
                _ColHeader('Timestamp', flex: 3),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── List ──
          Expanded(
            child: Obx(() {
              final c = _c;

              if (c.isLoading.value && c.messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (c.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No system messages found.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF9B97A8),
                    ),
                  ),
                );
              }

              return ListView.separated(
                controller: c.scrollController,
                itemCount: c.messages.length + (c.hasMore.value ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF2F2F2)),
                itemBuilder: (_, index) {
                  if (index == c.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  final msg = c.messages[index];
                  return _SystemMessageRow(
                    index: index + 1,
                    msg: msg,
                    fmt: _fmt,
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

class _SystemMessageRow extends StatelessWidget {
  final int index;
  final SystemMessage msg;
  final String Function(String?) fmt;

  const _SystemMessageRow({
    required this.index,
    required this.msg,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final completedName = msg.completedByUser?.username;

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAF9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$index',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF9B97A8),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              msg.body.isNotEmpty ? msg.body : '(media)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1730),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: msg.isCompleted && completedName != null
                ? Text(
                    completedName,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: const Color(0xFF27500A),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : _PendingChip(),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt(msg.messageTimestampUtc),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: const Color(0xFF9B97A8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Pending',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF633806),
        ),
      ),
    );
  }
}

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
