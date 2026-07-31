import 'package:flutter/material.dart';
import 'section_card.dart';

/// Generic typeahead search-select. Reused for both the truck and trailer
/// pickers — parameterized by item type + label extractors instead of each
/// screen building its own search field.
class VehicleSearchField<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? selected;
  final String Function(T item) titleOf;
  final String Function(T item)? subtitleOf;
  final List<InlineSpan> Function(T item)? subtitleSpansOf;
  final ValueChanged<T?> onSelected;
  final bool required;
  final String hint;

  const VehicleSearchField({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.titleOf,
    required this.onSelected,
    this.subtitleOf,
    this.subtitleSpansOf,
    this.required = false,
    this.hint = 'Search by number...',
  });

  @override
  State<VehicleSearchField<T>> createState() => _VehicleSearchFieldState<T>();
}

class _VehicleSearchFieldState<T> extends State<VehicleSearchField<T>> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.selected != null ? widget.titleOf(widget.selected as T) : '');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showResults = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VehicleSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == null && oldWidget.selected != null) {
      _controller.clear();
    } else if (widget.selected != null && widget.selected != oldWidget.selected) {
      // Covers programmatic re-selection (e.g. picking a suggested trailer from
      // the "not ready" dialog) — not just user typing/tapping in this field.
      _controller.text = widget.titleOf(widget.selected as T);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((e) => widget.titleOf(e).toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FieldLabel(
      label: widget.label,
      required: widget.required,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (text) {
                if (widget.selected != null &&
                    text != widget.titleOf(widget.selected as T)) {
                  widget.onSelected(null);
                }
                setState(() => _showResults = true);
              },
              onTap: () => setState(() => _showResults = true),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey.shade500, size: 20),
                suffixIcon: widget.selected != null
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: Colors.grey.shade500),
                        onPressed: () {
                          _controller.clear();
                          widget.onSelected(null);
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
          if (_showResults) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('No matches',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final item = _filtered[index];
                        return InkWell(
                          onTap: () {
                            _controller.text = widget.titleOf(item);
                            _focusNode.unfocus();
                            setState(() => _showResults = false);
                            widget.onSelected(item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.titleOf(item),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                if (widget.subtitleSpansOf != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey.shade500),
                                        children: widget.subtitleSpansOf!(item),
                                      ),
                                    ),
                                  )
                                else if (widget.subtitleOf != null)
                                  Text(
                                    widget.subtitleOf!(item),
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
