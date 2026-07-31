import 'package:flutter/material.dart';
import 'section_card.dart';

/// Plain labeled text input — used for license plates, temps, notes, and
/// remark fields instead of each repeating the same InputDecoration.
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FieldLabel(
      label: label,
      required: required,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
            border: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
        ),
      ),
    );
  }
}
