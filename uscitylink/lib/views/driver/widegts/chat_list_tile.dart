import 'package:flutter/material.dart';

/// Shared conversation-row UI for the Channels and Groups tabs, so both
/// lists read identically. Purely presentational — callers keep all their
/// own tap/dismiss logic.
class ChatListTile extends StatelessWidget {
  final Key dismissKey;
  final String name;
  final String? subtitle;
  final String? timeLabel;
  final int unreadCount;
  final VoidCallback onTap;
  final DismissDirectionCallback onDismissed;

  const ChatListTile({
    super.key,
    required this.dismissKey,
    required this.name,
    required this.subtitle,
    required this.timeLabel,
    required this.unreadCount,
    required this.onTap,
    required this.onDismissed,
  });

  static const List<Color> _avatarPalette = [
    Color(0xFF2E5BFF),
    Color(0xFF16A34A),
    Color(0xFF9333EA),
    Color(0xFFF59E0B),
    Color(0xFF0D9488),
    Color(0xFFDC2626),
  ];

  Color get _avatarColor {
    if (name.isEmpty) return _avatarPalette.first;
    return _avatarPalette[name.codeUnitAt(0) % _avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    final color = _avatarColor;

    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14.5,
                                color: Colors.grey.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLabel ?? '',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle ?? 'No message yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: hasUnread
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade500,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E5BFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared empty state for a chat list (no channels / no groups yet).
class ChatEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const ChatEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
