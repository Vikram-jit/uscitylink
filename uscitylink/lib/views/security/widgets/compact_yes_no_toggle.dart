import 'package:flutter/material.dart';

/// Compact single-row Yes/No toggle — label and two small pills share one
/// line, instead of YesNoToggle's label-above-full-width-pills layout. Used
/// for grouped inspection checklists where ~10 fields need to fit compactly.
class CompactYesNoToggle extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;

  const CompactYesNoToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (required)
                  const Text(' *',
                      style: TextStyle(
                          color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _pill('Yes', 'yes', const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          _pill('No', 'no', const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _pill(String text, String pillValue, Color color) {
    final selected = value == pillValue;
    return InkWell(
      onTap: () => onChanged(pillValue),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
