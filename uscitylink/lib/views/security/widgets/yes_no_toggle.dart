import 'package:flutter/material.dart';
import 'section_card.dart';

/// Reusable Yes/No pill toggle. Value convention is lowercase 'yes'/'no'
/// strings, matching the backend's string columns. Used for every boolean
/// inspection field so none of them hand-roll their own toggle UI.
class YesNoToggle extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;

  const YesNoToggle({
    super.key,
    required this.label,
    required this.value,
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
          Expanded(child: _pill('Yes', 'yes', const Color(0xFF16A34A))),
          const SizedBox(width: 10),
          Expanded(child: _pill('No', 'no', const Color(0xFFDC2626))),
        ],
      ),
    );
  }

  Widget _pill(String text, String pillValue, Color color) {
    final selected = value == pillValue;
    return InkWell(
      onTap: () => onChanged(pillValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.4,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
