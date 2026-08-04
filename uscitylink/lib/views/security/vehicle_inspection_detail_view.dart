import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/model/security/inspection_detail.dart';
import 'package:uscitylink/services/security/security_inspection_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'widgets/checklist_grid.dart';
import 'widgets/detail_row.dart';
import 'widgets/section_card.dart';

const Color _kAccentColor = Color(0xFF1B3B8C);

class VehicleInspectionDetailView extends StatefulWidget {
  final int inspectionId;

  const VehicleInspectionDetailView({super.key, required this.inspectionId});

  @override
  State<VehicleInspectionDetailView> createState() =>
      _VehicleInspectionDetailViewState();
}

class _VehicleInspectionDetailViewState extends State<VehicleInspectionDetailView> {
  final _service = SecurityInspectionService();
  bool _loading = true;
  InspectionDetail? _inspection;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await _service.getInspectionDetail(widget.inspectionId);
      setState(() {
        _inspection = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Utils.snackBar('Error', e.toString());
    }
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: _kAccentColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: const Text(
            'Inspection Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAccentColor))
            : _inspection == null
                ? Center(
                    child: Text('Inspection not found.',
                        style: TextStyle(color: Colors.grey.shade500)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryCard(_inspection!),
                        const SizedBox(height: 16),
                        _checklistSection(
                          title: 'Truck Inspection Checklist',
                          icon: Icons.local_shipping_rounded,
                          answers: _inspection!.truckAnswers,
                        ),
                        if (_inspection!.hasTrailer) ...[
                          const SizedBox(height: 16),
                          _checklistSection(
                            title: 'Trailer Inspection Checklist',
                            icon: Icons.rv_hookup_rounded,
                            answers: _inspection!.trailerAnswers,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _notesSection(_inspection!),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _summaryCard(InspectionDetail i) {
    final vehicleLabel = [
      if (i.truckNumber != null) 'Truck ${i.truckNumber}',
      if (i.trailerNumber != null) 'Trailer ${i.trailerNumber}',
    ].join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fact_check_rounded,
                color: _kAccentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleLabel.isEmpty ? 'Vehicle Inspection' : vehicleLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fmtDateTime(i.inspectedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistSection({
    required String title,
    required IconData icon,
    required List<dynamic> answers,
  }) {
    final okCount = answers.where((a) => a.status == 'ok').length;
    final problemCount = answers.where((a) => a.status == 'problem').length;

    // Flagged items surface first — what actually needs attention shouldn't
    // require scrolling past everything that passed to find it.
    final sorted = [...answers]..sort((a, b) {
        if (a.status == b.status) return 0;
        return a.status == 'problem' ? -1 : 1;
      });

    return SectionCard(
      title: title,
      icon: icon,
      subtitle: '$okCount OK'
          '${problemCount > 0 ? ' • $problemCount flagged' : ''}',
      accentColor: _kAccentColor,
      child: ChecklistGrid(
        items: sorted
            .map((a) => ChecklistItem(a.question, a.status,
                positiveValue: 'ok', negativeValue: 'problem'))
            .toList(),
      ),
    );
  }

  Widget _notesSection(InspectionDetail i) {
    return SectionCard(
      title: 'Notes & Sign-off',
      icon: Icons.edit_note_rounded,
      accentColor: _kAccentColor,
      child: Column(
        children: [
          DetailRow(label: 'Company Name', value: i.companyName),
          DetailRow(label: 'Odometer', value: i.odometer),
          if ((i.driverNames ?? '').isNotEmpty)
            DetailRow(label: 'Driver(s)', value: i.driverNames),
          DetailRow(label: 'Added By', value: i.addedBy),
          if ((i.note ?? '').isNotEmpty) DetailRow(label: 'Note', value: i.note),
        ],
      ),
    );
  }
}
