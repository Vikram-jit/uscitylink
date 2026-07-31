import 'package:flutter/material.dart';
import 'section_card.dart';

class ChoicePillOption {
  final String value;
  final String label;
  final Color color;
  const ChoicePillOption(this.value, this.label, this.color);
}

/// Segmented pill selector for a small, fixed set of mutually-exclusive
/// options (Empty/Loaded, Refer/Dry) — same visual language as YesNoToggle,
/// generalized to custom labels/colors instead of a plain dropdown menu, so
/// picking one is a single visible tap rather than open-menu-then-select.
class ChoicePills extends StatelessWidget {
  final String label;
  final bool required;
  final String? value;
  final List<ChoicePillOption> options;
  final ValueChanged<String> onChanged;

  const ChoicePills({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return FieldLabel(
      label: label,
      required: required,
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(child: _pill(options[i])),
          ],
        ],
      ),
    );
  }

  Widget _pill(ChoicePillOption option) {
    final selected = value == option.value;
    return InkWell(
      onTap: () => onChanged(option.value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? option.color.withOpacity(0.1) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? option.color : Colors.grey.shade200,
            width: 1.4,
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? option.color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
