import 'package:flutter/material.dart';

/// Label + value row for read-only detail screens — the display counterpart
/// to FieldLabel, used throughout VehicleEntryDetailView.
class DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = valueWidget == null && (value == null || value!.trim().isEmpty);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: valueWidget ??
                Text(
                  isEmpty ? '—' : value!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isEmpty ? Colors.grey.shade400 : Colors.grey.shade900,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Small colored pill used for status-like values (Yes/No, Empty/Loaded)
/// inside a DetailRow's valueWidget slot.
class DetailBadge extends StatelessWidget {
  final String text;
  final Color color;

  const DetailBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
