import 'package:flutter/material.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// Reject (outlined) and Accept (filled) side by side — the driver's answer to a load. One tap each, no
/// questions: Reject sends the load straight back to dispatch (they are told in the chat).
class AcceptRejectRow extends StatelessWidget {
  const AcceptRejectRow({super.key, required this.acceptKey, required this.rejectKey, required this.onAccept, required this.onReject, this.busy = false, this.acceptLabel = 'Accept'});
  final Key acceptKey;
  final Key rejectKey;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;
  final String acceptLabel;

  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 5,
        child: OutlinedButton.icon(
          key: rejectKey,
          style: OutlinedButton.styleFrom(foregroundColor: _red, side: const BorderSide(color: _red), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
          onPressed: busy ? null : onReject,
          icon: const Icon(Icons.close_rounded, size: 20),
          label: const Text('Reject', maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        flex: 6,
        child: FilledButton.icon(
          key: acceptKey,
          style: FilledButton.styleFrom(backgroundColor: _green, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md))),
          onPressed: busy ? null : onAccept,
          icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 20),
          label: Text(acceptLabel, maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
        ),
      ),
    ]);
  }
}
