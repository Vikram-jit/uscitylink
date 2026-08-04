import 'package:flutter/material.dart';

/// Compact single-row 2-choice toggle — label and two small pills share one
/// line, instead of YesNoToggle's label-above-full-width-pills layout. Used
/// for grouped checklists where many fields need to fit compactly. Defaults
/// to Yes/No (green/red) but the pill text/values/colors can be overridden
/// (e.g. OK/Problem for vehicle inspection checklists) without duplicating
/// this widget.
class CompactYesNoToggle extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;
  final String positiveLabel;
  final String positiveValue;
  final Color positiveColor;
  final String negativeLabel;
  final String negativeValue;
  final Color negativeColor;

  const CompactYesNoToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.positiveLabel = 'Yes',
    this.positiveValue = 'yes',
    this.positiveColor = const Color(0xFF16A34A),
    this.negativeLabel = 'No',
    this.negativeValue = 'no',
    this.negativeColor = const Color(0xFFDC2626),
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
          _pill(positiveLabel, positiveValue, positiveColor),
          const SizedBox(width: 6),
          _pill(negativeLabel, negativeValue, negativeColor),
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
