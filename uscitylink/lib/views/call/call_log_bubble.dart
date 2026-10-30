import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/model/message_model.dart';

/// The call-log message in a chat ("Voice call · 3:42", "Missed voice call").
/// [viewerIsDriver] decides the wording: direction "S" means dispatch placed the call.
class CallLogBubble extends StatelessWidget {
  const CallLogBubble({super.key, required this.message, required this.viewerIsDriver, this.onCallBack});

  final MessageModel message;
  final bool viewerIsDriver;
  final VoidCallback? onCallBack;

  @override
  Widget build(BuildContext context) {
    final body = message.body ?? 'Voice call';
    final missed = RegExp(r'^(Missed|Declined)|failed', caseSensitive: false).hasMatch(body);
    final dispatchCalled = message.messageDirection == 'S';
    final mine = viewerIsDriver ? !dispatchCalled : dispatchCalled;
    final who = dispatchCalled ? 'Dispatch called' : (viewerIsDriver ? 'You called dispatch' : 'Driver called');
    String time = '';
    try {
      final t = DateTime.parse('${message.messageTimestampUtc ?? message.createdAt}').toLocal();
      time = DateFormat('h:mm a').format(t);
    } catch (_) {}

    final accent = missed ? const Color(0xFFEF4444) : const Color(0xFF16A34A);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Material(
          color: missed ? const Color(0xFFFEF2F2) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: missed ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onCallBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: Icon(
                      missed ? Icons.phone_missed_rounded : (mine ? Icons.call_made_rounded : Icons.call_received_rounded),
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(body, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(
                          [who, if (time.isNotEmpty) time].join(' · '),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (onCallBack != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.call_rounded, size: 18, color: accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
