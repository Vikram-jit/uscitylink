// Custom input field widget for reusability
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.prefix,
    this.validator,
    this.maxLines = 1,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            if (label.contains('name'))
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFF4A154B),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: Colors.black),
          controller: controller,
          maxLines: maxLines,
          focusNode: focusNode,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 8,
                    ),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefix != null ? 8 : 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A154B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
