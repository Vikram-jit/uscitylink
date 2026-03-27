import 'package:flutter/material.dart';

class MultiSelectAutoCompleteField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<T> items;
  final String Function(T) displayText;
  final List<T> selectedItems;
  final Function(List<T>) onChanged;

  const MultiSelectAutoCompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.displayText,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  State<MultiSelectAutoCompleteField<T>> createState() =>
      _MultiSelectAutoCompleteFieldState<T>();
}

class _MultiSelectAutoCompleteFieldState<T>
    extends State<MultiSelectAutoCompleteField<T>> {
  final TextEditingController _searchController = TextEditingController();

  List<T> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
  }

  /// ✅ HANDLE API / LIST UPDATE
  @override
  void didUpdateWidget(covariant MultiSelectAutoCompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items) {
      filtered = widget.items;
    }
  }

  /// 🔍 FILTER
  void _filter(String value) {
    setState(() {
      filtered = widget.items.where((item) {
        return widget
            .displayText(item)
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  /// 🔁 TOGGLE SELECT
  void _toggle(T item) {
    final selected = List<T>.from(widget.selectedItems);

    if (selected.contains(item)) {
      selected.removeWhere((e) => e == item);
    } else {
      selected.add(item);
    }

    widget.onChanged(selected);

    setState(() {}); // 🔥 force UI update
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ================= LABEL =================
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),

        const SizedBox(height: 8),

        /// ================= SEARCH =================
        TextField(
          controller: _searchController,
          onChanged: _filter,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 10),

        /// ================= SELECTED CHIPS =================
        if (widget.selectedItems.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedItems.map((item) {
              return Chip(
                label: Text(widget.displayText(item)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _toggle(item),
              );
            }).toList(),
          ),

        const SizedBox(height: 10),

        /// ================= DROPDOWN =================
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "No results found",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final isSelected = widget.selectedItems.contains(item);

                    return InkWell(
                      onTap: () => _toggle(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggle(item),
                            ),
                            Expanded(
                              child: Text(
                                widget.displayText(item),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
