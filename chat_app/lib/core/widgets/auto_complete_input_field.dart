import 'package:flutter/material.dart';

class AutoCompleteInputField<T extends Object> extends StatelessWidget {
  final String label;
  final String hint;

  /// full list
  final List<T> items;

  /// how to display text
  final String Function(T) displayText;

  /// on select item
  final Function(T) onSelected;

  /// optional controller
  final TextEditingController? controller;

  const AutoCompleteInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.displayText,
    required this.onSelected,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller =
        controller ?? TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LABEL
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),

        const SizedBox(height: 8),

        /// AUTOCOMPLETE
        Autocomplete<T>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return items;
            }

            return items.where((item) {
              return displayText(item)
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },

          displayStringForOption: displayText,

          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            _controller.text = textController.text;

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.black),

              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A154B),
                    width: 2,
                  ),
                ),
              ),
            );
          },

          onSelected: (T selection) {
            _controller.text = displayText(selection);
            onSelected(selection);
          },

          /// DROPDOWN UI
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);

                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            displayText(option),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}