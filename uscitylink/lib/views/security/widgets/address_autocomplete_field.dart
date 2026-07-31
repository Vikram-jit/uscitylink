import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uscitylink/model/security/place_models.dart';
import 'package:uscitylink/services/security/places_service.dart';
import 'section_card.dart';

/// Debounced address field backed by the Places proxy. Falls back to plain
/// manual typing gracefully — if the backend has no Places API key
/// configured yet, autocomplete just returns no suggestions and the field
/// still works as a normal text input.
class AddressAutocompleteField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<PlaceDetails> onPlaceSelected;
  final bool required;

  const AddressAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    required this.onPlaceSelected,
    this.required = false,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final PlacesService _placesService = PlacesService();
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _loading = false;

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 4) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loading = true);
      final results = await _placesService.autocomplete(value);
      if (!mounted) return;
      setState(() {
        _predictions = results;
        _loading = false;
      });
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() {
      widget.controller.text = prediction.description;
      _predictions = [];
      _loading = true;
    });
    final details = await _placesService.getDetails(prediction.placeId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (details != null) {
      if (details.address.isNotEmpty) {
        widget.controller.text = details.address;
      }
      widget.onPlaceSelected(details);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
              controller: widget.controller,
              onChanged: _onChanged,
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Delivery address...',
                hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: Colors.grey.shade500, size: 20),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
          if (_predictions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _predictions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return InkWell(
                    onTap: () => _selectPrediction(prediction),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prediction.description,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade800),
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
        ],
      ),
    );
  }
}
