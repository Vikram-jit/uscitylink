import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/modules/system_messages/system_message_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemMessageFilters extends StatefulWidget {
  const SystemMessageFilters({super.key});

  @override
  State<SystemMessageFilters> createState() => _SystemMessageFiltersState();
}

class _SystemMessageFiltersState extends State<SystemMessageFilters> {
  final _searchCtrl = TextEditingController();
  SystemMessageController get _c => Get.find<SystemMessageController>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (isStart) {
      _c.onStartDateChange(formatted);
    } else {
      _c.onEndDateChange(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Filters',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1730),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          _label('Search'),
          const SizedBox(height: 6),
          TextField(
            controller: _searchCtrl,
            onChanged: _c.onSearchChange,
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: _inputDecoration('Search messages...'),
          ),
          const SizedBox(height: 14),

          // Completed By dropdown
          _label('Completed By (Staff)'),
          const SizedBox(height: 6),
          Obx(() {
            final staff = _c.staffUsers;
            final selected =
                _c.completedByFilter.value.isEmpty ? null : _c.completedByFilter.value;

            return DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black87),
              decoration: _inputDecoration('All staff'),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All', style: GoogleFonts.dmSans(fontSize: 13)),
                ),
                ...staff.map(
                  (u) => DropdownMenuItem<String>(
                    value: u.id,
                    child: Text(
                      u.username ?? u.id ?? '',
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                  ),
                ),
              ],
              onChanged: _c.onCompletedByChange,
            );
          }),
          const SizedBox(height: 14),

          // From Date
          _label('From Date'),
          const SizedBox(height: 6),
          Obx(() {
            final val = _c.startDate.value;
            return GestureDetector(
              onTap: () => _pickDate(true),
              child: _DateField(value: val.isEmpty ? 'Select date' : val),
            );
          }),
          const SizedBox(height: 14),

          // To Date
          _label('To Date'),
          const SizedBox(height: 6),
          Obx(() {
            final val = _c.endDate.value;
            return GestureDetector(
              onTap: () => _pickDate(false),
              child: _DateField(value: val.isEmpty ? 'Select date' : val),
            );
          }),
          const SizedBox(height: 20),

          // Clear filters button
          Obx(() {
            if (!_c.hasActiveFilters) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  _c.clearFilters();
                },
                icon: const Icon(Icons.clear, size: 16),
                label: Text(
                  'Clear Filters',
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF444441),
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A5670),
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF9B97A8)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );
}

class _DateField extends StatelessWidget {
  final String value;
  const _DateField({required this.value});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'Select date';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF9B97A8)),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isPlaceholder ? const Color(0xFF9B97A8) : const Color(0xFF1A1730),
            ),
          ),
        ],
      ),
    );
  }
}
