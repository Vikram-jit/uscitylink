import 'package:flutter/material.dart';
import 'section_card.dart';

/// Generic labeled dropdown — reused for fuel selects, empty/loaded, and
/// load type instead of each field building its own DropdownButtonFormField.
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String hint;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.required = false,
    this.hint = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    return FieldLabel(
      label: label,
      required: required,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500)),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade500),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
            items: options
                .map((o) => DropdownMenuItem<T>(
                      value: o,
                      child: Text(labelBuilder(o)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
