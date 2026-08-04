import 'package:flutter/material.dart';

/// A single 2-choice inspection answer to render inside a ChecklistGrid.
/// `positiveValue` defaults to 'yes' (Entry/Exit toggles); pass 'ok' for
/// OK/Problem-style checklists (Vehicle Inspection) without duplicating this
/// widget.
class ChecklistItem {
  final String label;
  final String? answer; // matches positiveValue, negativeValue, or null (unanswered)
  final String positiveValue;
  final String negativeValue;

  const ChecklistItem(
    this.label,
    this.answer, {
    this.positiveValue = 'yes',
    this.negativeValue = 'no',
  });
}

/// Compact 2-column grid of Yes/No inspection answers — replaces a long
/// stack of individual DetailRows with scannable colored chips, used on the
/// entry detail screen's Trailer & Inspection section.
class ChecklistGrid extends StatelessWidget {
  final List<ChecklistItem> items;

  const ChecklistGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(width: itemWidth, child: _chip(item)))
              .toList(),
        );
      },
    );
  }

  Widget _chip(ChecklistItem item) {
    final isPositive = item.answer == item.positiveValue;
    final isNegative = item.answer == item.negativeValue;
    final color = isPositive
        ? const Color(0xFF16A34A)
        : (isNegative ? const Color(0xFFDC2626) : Colors.grey.shade400);
    final icon = isPositive
        ? Icons.check_circle_rounded
        : (isNegative ? Icons.cancel_rounded : Icons.remove_circle_outline_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: isNegative
            ? Border(left: BorderSide(color: color, width: 3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
