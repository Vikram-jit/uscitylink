import 'package:flutter/material.dart';
import 'package:uscitylink/model/security/security_driver_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'section_card.dart';

/// Reusable driver multi-select — a search + checkbox-list bottom sheet
/// (same shape as lib/views/staff/widgets/driver_dialog.dart, but generic:
/// works over a plain list passed in rather than a specific controller).
class DriverMultiSelectField extends StatelessWidget {
  final String label;
  final List<SecurityDriverModel> drivers;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  const DriverMultiSelectField({
    super.key,
    required this.label,
    required this.drivers,
    required this.selectedIds,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverPickerSheet(
        drivers: drivers,
        initialSelectedIds: selectedIds,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = drivers
        .where((d) => selectedIds.contains(d.id))
        .map((d) => d.name ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');

    return FieldLabel(
      label: label,
      child: InkWell(
        onTap: () => _open(context),
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
              Icon(Icons.person_add_alt_1_rounded,
                  size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedNames.isEmpty
                      ? 'Select driver(s)'
                      : selectedNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        selectedNames.isEmpty ? FontWeight.w500 : FontWeight.w600,
                    color: selectedNames.isEmpty
                        ? Colors.grey.shade500
                        : Colors.grey.shade900,
                  ),
                ),
              ),
              if (selectedIds.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: TColors.navyHeader.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${selectedIds.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TColors.navyHeader)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverPickerSheet extends StatefulWidget {
  final List<SecurityDriverModel> drivers;
  final List<int> initialSelectedIds;

  const _DriverPickerSheet({
    required this.drivers,
    required this.initialSelectedIds,
  });

  @override
  State<_DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends State<_DriverPickerSheet> {
  late Set<int> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.drivers
        .where((d) =>
            (d.name ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Select Driver(s)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search drivers...',
                    hintStyle:
                        TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey.shade500, size: 20),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No drivers found',
                            style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final driver = filtered[index];
                          final checked = _selected.contains(driver.id);
                          return CheckboxListTile(
                            value: checked,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: TColors.navyHeader,
                            contentPadding: EdgeInsets.zero,
                            title: Text(driver.name ?? '',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(driver.id ?? -1);
                                } else {
                                  _selected.remove(driver.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.navyHeader,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done (${_selected.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
