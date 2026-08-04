import 'package:flutter/material.dart';

/// Icon-button OK/Problem toggle for vehicle inspection checklists — always
/// tinted with its color (not flat gray) so the two options read at a glance
/// without needing to read the text, and fills solid once selected.
class InspectionAnswerToggle extends StatelessWidget {
  final String label;
  final String? value; // 'ok' | 'problem' | null (unanswered)
  final ValueChanged<String> onChanged;

  static const _okColor = Color(0xFF16A34A);
  static const _problemColor = Color(0xFFDC2626);

  const InspectionAnswerToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _iconButton(Icons.check_rounded, 'ok', _okColor),
          const SizedBox(width: 8),
          _iconButton(Icons.priority_high_rounded, 'problem', _problemColor),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String v, Color color) {
    final selected = value == v;
    return InkWell(
      onTap: () => onChanged(v),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.3),
            width: 1.3,
          ),
        ),
        child: Icon(icon, size: 17, color: selected ? Colors.white : color),
      ),
    );
  }
}
