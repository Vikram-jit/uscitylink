import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'section_card.dart';

/// Reusable date+time picker field — used for both Deliver At and
/// Departure At instead of duplicating the picker plumbing twice.
class LabeledDateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool required;
  final DateTime? firstDate;
  final String hint;

  const LabeledDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.hint = 'Select date & time',
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return FieldLabel(
      label: label,
      required: required,
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.event_rounded, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value != null
                      ? DateFormat('MMM d, yyyy • h:mm a').format(value!)
                      : hint,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.w500,
                    color: value != null ? Colors.grey.shade900 : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
