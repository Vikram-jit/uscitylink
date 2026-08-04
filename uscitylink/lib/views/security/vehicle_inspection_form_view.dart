import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart'
    show kSecurityGuardOptions;
import 'package:uscitylink/controller/vehicle_inspection_form_controller.dart';
import 'package:uscitylink/model/security/security_trailer_model.dart';
import 'package:uscitylink/model/security/security_truck_model.dart';
import 'widgets/driver_multi_select_field.dart';
import 'widgets/inspection_answer_toggle.dart';
import 'widgets/labeled_date_time_field.dart';
import 'widgets/labeled_dropdown.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/section_card.dart';
import 'widgets/vehicle_search_field.dart';

const Color _kAccentColor = Color(0xFF1B3B8C);

// Purely a UI grouping convenience (doesn't affect submitted data) — any
// question not found here falls back into an "Other" group, so the form
// still renders correctly even if the backend's question list ever changes.
const Map<String, String> _kTruckGroups = {
  'Coolant Level': 'Engine & Fluids',
  'Engine Oil Level': 'Engine & Fluids',
  'Extra Oil & Coolant Gallon': 'Engine & Fluids',
  'Radiator': 'Engine & Fluids',
  'Oil Pressure': 'Engine & Fluids',
  'Fire Extinguisher': 'Safety Equipment',
  'Reflectors': 'Safety Equipment',
  'Reflective Triangles': 'Safety Equipment',
  'Spare Bulbs And Fuses': 'Safety Equipment',
  'Jumper Cable': 'Safety Equipment',
  'Horn': 'Safety Equipment',
  'Head/Stop': 'Lighting & Electrical',
  'Tail/Dash': 'Lighting & Electrical',
  'Turn Indicators': 'Lighting & Electrical',
  'ClearanceMarker': 'Lighting & Electrical',
  'Front Tires': 'Tires & Wheels',
  'Drive Tires': 'Tires & Wheels',
  'Wheels And Rims': 'Tires & Wheels',
  'Wheel Seal': 'Tires & Wheels',
  'Body': 'Body & Structure',
  'Windows': 'Body & Structure',
  'Windshield Wipers': 'Body & Structure',
  'Mirrors': 'Body & Structure',
  'Rear End': 'Body & Structure',
  'Starter': 'Mechanical & Air System',
  'Steering': 'Mechanical & Air System',
  'Fuel Tanks': 'Mechanical & Air System',
  'Air Lines': 'Mechanical & Air System',
  'Belts And Hoses': 'Mechanical & Air System',
};

const Map<String, String> _kTrailerGroups = {
  'Doors': 'Structural',
  'Landing Gear': 'Structural',
  'Suspension System': 'Structural',
  'Wheels And Rims': 'Structural',
  'Wheel Seal': 'Structural',
  'Fire Extinguisher': 'Safety Equipment',
  'Warning Triangles': 'Safety Equipment',
  'Reflectors/Reflective Tape': 'Safety Equipment',
  'Spare Tire': 'Safety Equipment',
  'Lights - All': 'Lighting & Refer',
  'Refer Set Temp.': 'Lighting & Refer',
  'Tires': 'Tires & Seals',
  'Trailer Seal': 'Tires & Seals',
  'Load Lock': 'Tires & Seals',
  'Brakes': 'Tires & Seals',
  'Fuel Card': 'Documentation',
  'Log Book': 'Documentation',
  'Paper Work': 'Documentation',
  'License Plate': 'Documentation',
};

Map<String, List<String>> _groupQuestions(
    List<String> questions, Map<String, String> groupMap) {
  final grouped = <String, List<String>>{};
  for (final q in questions) {
    final group = groupMap[q] ?? 'Other';
    grouped.putIfAbsent(group, () => []).add(q);
  }
  return grouped;
}

class VehicleInspectionFormView extends StatefulWidget {
  final int? initialTruckId;

  const VehicleInspectionFormView({super.key, this.initialTruckId});

  @override
  State<VehicleInspectionFormView> createState() =>
      _VehicleInspectionFormViewState();
}

class _VehicleInspectionFormViewState extends State<VehicleInspectionFormView> {
  late final VehicleInspectionFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
        VehicleInspectionFormController(initialTruckId: widget.initialTruckId));
  }

  @override
  void dispose() {
    Get.delete<VehicleInspectionFormController>();
    super.dispose();
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
            'Vehicle Inspection',
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
        body: Obx(() {
          if (_controller.loadingFormData.value) {
            return const Center(
                child: CircularProgressIndicator(color: _kAccentColor));
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _vehicleSection(),
                const SizedBox(height: 16),
                _checklistSection(
                  title: 'Truck Inspection Checklist',
                  icon: Icons.fact_check_rounded,
                  questions: _controller.truckQuestions,
                  groupMap: _kTruckGroups,
                  answers: _controller.truckAnswers,
                  onAnswer: _controller.setTruckAnswer,
                ),
                if (_controller.hasTrailer) ...[
                  const SizedBox(height: 16),
                  _checklistSection(
                    title: 'Trailer Inspection Checklist',
                    icon: Icons.rv_hookup_rounded,
                    questions: _controller.trailerQuestions,
                    groupMap: _kTrailerGroups,
                    answers: _controller.trailerAnswers,
                    onAnswer: _controller.setTrailerAnswer,
                  ),
                ],
                const SizedBox(height: 16),
                _notesSection(),
                const SizedBox(height: 24),
                _submitButton(),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _vehicleSection() {
    final c = _controller;
    return SectionCard(
      title: 'Vehicle & Odometer',
      icon: Icons.local_shipping_rounded,
      accentColor: _kAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleSearchField<SecurityTruckModel>(
            label: 'Truck Number',
            required: true,
            items: c.trucks,
            selected: c.selectedTruck.value,
            titleOf: (t) => t.number ?? '',
            hint: 'Search truck number...',
            onSelected: c.selectTruck,
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: c.loadingOdometer.value
                ? 'Odometer (loading...)'
                : 'Odometer (miles)',
            controller: c.odometerController,
            keyboardType: TextInputType.number,
            hint: 'Auto-filled from truck telemetry when available',
          ),
          const SizedBox(height: 14),
          VehicleSearchField<SecurityTrailerModel>(
            label: 'Trailer Number',
            items: c.trailers,
            selected: c.selectedTrailer.value,
            titleOf: (t) => t.number ?? '',
            subtitleSpansOf: (t) {
              final badges = t.statusBadges;
              if (badges.isEmpty) return [];
              final spans = <InlineSpan>[const TextSpan(text: '(')];
              for (var i = 0; i < badges.length; i++) {
                if (i != 0) spans.add(const TextSpan(text: ', '));
                spans.add(TextSpan(
                  text: badges[i].label,
                  style: TextStyle(
                      color: badges[i].color, fontWeight: FontWeight.w700),
                ));
              }
              spans.add(const TextSpan(text: ')'));
              return spans;
            },
            hint: 'Optional — leave blank for truck-only inspection',
            onSelected: c.selectTrailer,
          ),
        ],
      ),
    );
  }

  Widget _checklistSection({
    required String title,
    required IconData icon,
    required List<String> questions,
    required Map<String, String> groupMap,
    required Map<String, String?> answers,
    required void Function(String question, String status) onAnswer,
  }) {
    final grouped = _groupQuestions(questions, groupMap);
    final answeredCount = questions.where((q) => answers[q] != null).length;
    final problemCount = questions.where((q) => answers[q] == 'problem').length;

    return SectionCard(
      title: title,
      icon: icon,
      subtitle: '$answeredCount of ${questions.length} answered'
          '${problemCount > 0 ? ' • $problemCount flagged' : ''}',
      accentColor: _kAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in grouped.entries)
            _checklistGroupCard(entry.key, entry.value, answers, onAnswer),
        ],
      ),
    );
  }

  Widget _checklistGroupCard(
    String groupTitle,
    List<String> groupQuestions,
    Map<String, String?> answers,
    void Function(String question, String status) onAnswer,
  ) {
    final answeredInGroup =
        groupQuestions.where((q) => answers[q] != null).length;
    final allAnswered = answeredInGroup == groupQuestions.length;
    final badgeColor =
        allAnswered ? const Color(0xFF16A34A) : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: _kAccentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  groupTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: allAnswered
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Color(0xFF16A34A))
                    : Text(
                        '$answeredInGroup/${groupQuestions.length}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final q in groupQuestions)
            InspectionAnswerToggle(
              label: q,
              value: answers[q],
              onChanged: (v) => onAnswer(q, v),
            ),
        ],
      ),
    );
  }

  Widget _notesSection() {
    final c = _controller;
    return SectionCard(
      title: 'Notes & Sign-off',
      icon: Icons.edit_note_rounded,
      accentColor: _kAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledTextField(
            label: 'Company Name',
            controller: c.companyNameController,
          ),
          const SizedBox(height: 14),
          LabeledDateTimeField(
            label: 'Inspection Date',
            required: true,
            value: c.inspectedAt.value,
            onChanged: (dt) => c.inspectedAt.value = dt,
          ),
          const SizedBox(height: 14),
          DriverMultiSelectField(
            label: 'Driver(s)',
            drivers: c.drivers,
            selectedIds: c.selectedDriverIds,
            onChanged: (ids) => c.selectedDriverIds.value = ids,
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'Note',
            controller: c.noteController,
            maxLines: 4,
            hint: 'Any additional notes...',
          ),
          const SizedBox(height: 14),
          LabeledDropdown<String>(
            label: 'Security',
            required: true,
            value: c.selectedSecurity.value,
            options: kSecurityGuardOptions,
            labelBuilder: (v) => v,
            hint: 'Select Security',
            onChanged: (v) => c.selectedSecurity.value = v,
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _controller.submitting.value
                ? null
                : () async {
                    final success = await _controller.submit();
                    // if (success && mounted) Get.back(result: true);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _controller.submitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Submit Inspection',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ));
  }
}
