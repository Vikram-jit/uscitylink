import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart';
import 'package:uscitylink/model/security/security_trailer_model.dart';
import 'package:uscitylink/model/security/security_truck_model.dart';
import 'package:uscitylink/model/security/trailer_status_check_result.dart';
import 'widgets/address_autocomplete_field.dart';
import 'widgets/choice_pills.dart';
import 'widgets/compact_yes_no_toggle.dart';
import 'widgets/driver_multi_select_field.dart';
import 'widgets/labeled_date_time_field.dart';
import 'widgets/labeled_dropdown.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/section_card.dart';
import 'widgets/vehicle_search_field.dart';
import 'widgets/yes_no_toggle.dart';
import 'vehicle_entry_list_view.dart';

const _fuelOptions = ['empty', '1Q', 'half', '3Q', 'full'];

String _fuelLabel(String v) {
  switch (v) {
    case 'empty':
      return 'Empty';
    case '1Q':
      return '1Q';
    case 'half':
      return 'half';
    case '3Q':
      return '3Q';
    case 'full':
      return 'Full';
    default:
      return v;
  }
}

class VehicleEntryFormView extends StatefulWidget {
  final VehicleEntryStatus status;

  const VehicleEntryFormView({super.key, required this.status});

  @override
  State<VehicleEntryFormView> createState() => _VehicleEntryFormViewState();
}

class _VehicleEntryFormViewState extends State<VehicleEntryFormView> {
  late final String _tag;
  late final VehicleEntryFormController _controller;

  @override
  void initState() {
    super.initState();
    _tag = widget.status.name;
    _controller = Get.put(VehicleEntryFormController(widget.status), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<VehicleEntryFormController>(tag: _tag);
    super.dispose();
  }

  Color get _accentColor => widget.status == VehicleEntryStatus.entry
      ? const Color(0xFF16A34A)
      : const Color(0xFFDC2626);

  /// Runs the Exit-only "empty trailer not ready" check and shows the blocking
  /// dialog if needed. Returns true when it's fine to proceed (not blocked, or
  /// the check doesn't apply for this status/empty-loaded combination).
  Future<bool> _runTrailerReadinessCheck() async {
    final blocked = await _controller.checkTrailerReadiness();
    if (blocked == null) return true;
    if (!mounted) return false;
    await _showTrailerBlockedDialog(blocked);
    return false;
  }

  Future<void> _showTrailerBlockedDialog(TrailerStatusCheckResult result) async {
    final label = VehicleEntryFormController.readyStatusLabel(result.readyStatus);
    final reason = label.isNotEmpty
        ? 'it is $label'
        : 'it was not found in the Daily Vehicle Sheet';
    final trailerNumber =
        result.trailerNumber ?? _controller.selectedTrailer.value?.number ?? '';

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Expanded(
              child: Text('Trailer Not Ready',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You cannot take trailer number $trailerNumber out, because '
                '$reason. Please contact the dispatch team to do this.',
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey.shade800, height: 1.4),
              ),
              if (result.readyTrailers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Select a ready trailer instead',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                ...result.readyTrailers.map((t) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.rv_hookup_rounded,
                          color: Color(0xFF16A34A)),
                      title: Text('Trailer ${t.number}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        _controller.selectReadyTrailer(t);
                        Navigator.of(dialogContext).pop();
                      },
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          backgroundColor: _accentColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            widget.status.label,
            style: const TextStyle(
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
            return Center(
                child: CircularProgressIndicator(color: _accentColor));
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _truckSection(),
                const SizedBox(height: 16),
                _trailerSection(),
                if (_controller.hasTrailer && _controller.isLoaded) ...[
                  const SizedBox(height: 16),
                  _deliverySection(),
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

  Widget _groupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _truckSection() {
    return SectionCard(
      title: 'Truck Details',
      icon: Icons.local_shipping_rounded,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleSearchField<SecurityTruckModel>(
            label: 'Truck Number',
            required: true,
            items: _controller.trucks,
            selected: _controller.selectedTruck.value,
            titleOf: (t) => t.number ?? '',
            hint: 'Search truck number...',
            onSelected: _controller.selectTruck,
          ),
          const SizedBox(height: 14),
          LabeledDropdown<String>(
            label: 'Truck Fuel',
            required: true,
            value: _controller.truckFuel.value,
            options: _fuelOptions,
            labelBuilder: _fuelLabel,
            onChanged: (v) => _controller.truckFuel.value = v,
          ),
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'Truck License Plate',
            required: true,
            controller: _controller.truckLicensePlateController,
            hint: 'License plate number',
          ),
        ],
      ),
    );
  }

  Widget _trailerSection() {
    final c = _controller;
    return SectionCard(
      title: 'Trailer Details',
      subtitle: c.hasTrailer ? null : 'Optional — leave blank for a truck-only entry',
      icon: Icons.rv_hookup_rounded,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            hint: 'Search trailer number...',
            onSelected: (t) {
              c.selectTrailer(t);
              _runTrailerReadinessCheck();
            },
          ),
          if (c.hasTrailer) ...[
            const SizedBox(height: 14),
            LabeledDropdown<String>(
              label: 'Trailer Fuel',
              required: true,
              value: c.trailerFuel.value,
              options: _fuelOptions,
              labelBuilder: _fuelLabel,
              onChanged: (v) => c.trailerFuel.value = v,
            ),
            const SizedBox(height: 14),
            LabeledTextField(
              label: 'Trailer License Plate',
              required: true,
              controller: c.trailerLicensePlateController,
            ),
            const SizedBox(height: 14),
            ChoicePills(
              label: 'Empty or Loaded',
              required: true,
              value: c.emptyLoaded.value,
              options: const [
                ChoicePillOption('empty', 'Empty', Color(0xFF6B7280)),
                ChoicePillOption('loaded', 'Loaded', Color(0xFF2563EB)),
              ],
              onChanged: (v) {
                c.emptyLoaded.value = v;
                _runTrailerReadinessCheck();
              },
            ),
            const SizedBox(height: 18),
            _groupHeader('Truck & Trailer Condition'),
            CompactYesNoToggle(
                label: 'Truck Key Attached',
                required: true,
                value: c.truckKeyAttached.value,
                onChanged: (v) => c.truckKeyAttached.value = v),
            CompactYesNoToggle(
                label: 'Truck Matt',
                required: true,
                value: c.truckMatt.value,
                onChanged: (v) => c.truckMatt.value = v),
            CompactYesNoToggle(
                label: 'Spare Tyre',
                required: true,
                value: c.spareTyre.value,
                onChanged: (v) => c.spareTyre.value = v),
            CompactYesNoToggle(
                label: 'Fire Extinguisher',
                required: true,
                value: c.fireExt.value,
                onChanged: (v) => c.fireExt.value = v),
            CompactYesNoToggle(
                label: 'Warning Triangles',
                required: true,
                value: c.warningTriangles.value,
                onChanged: (v) => c.warningTriangles.value = v),
            CompactYesNoToggle(
                label: 'Damage',
                required: true,
                value: c.damage.value,
                onChanged: (v) => c.damage.value = v),
            if (c.damage.value == 'yes') ...[
              const SizedBox(height: 6),
              LabeledTextField(
                label: 'Damage Description',
                controller: c.damageDescriptionController,
                maxLines: 3,
                hint: 'Describe the damage...',
              ),
            ],
            const SizedBox(height: 14),
            _groupHeader('Documentation & Inspection'),
            CompactYesNoToggle(
                label: 'Log Book Stand',
                required: true,
                value: c.logBookStand.value,
                onChanged: (v) => c.logBookStand.value = v),
            CompactYesNoToggle(
                label: 'Security Guard Inspected',
                required: true,
                value: c.securityGuardInspect.value,
                onChanged: (v) => c.securityGuardInspect.value = v),
            CompactYesNoToggle(
                label: 'Annual Inspection',
                required: true,
                value: c.anualInspection.value,
                onChanged: (v) => c.anualInspection.value = v),
            CompactYesNoToggle(
                label: 'Registration',
                required: true,
                value: c.registration.value,
                onChanged: (v) => c.registration.value = v),
            if (c.isLoaded) ...[
              const SizedBox(height: 14),
              _groupHeader('Load Details'),
              ChoicePills(
                label: 'Load Type',
                required: true,
                value: c.loadType.value,
                options: const [
                  ChoicePillOption('refer', 'Refer', Color(0xFF0EA5E9)),
                  ChoicePillOption('dry', 'Dry', Color(0xFF9333EA)),
                ],
                onChanged: (v) => c.loadType.value = v,
              ),
              const SizedBox(height: 4),
              CompactYesNoToggle(
                  label: 'Seal',
                  required: true,
                  value: c.seal.value,
                  onChanged: (v) => c.seal.value = v),
              CompactYesNoToggle(
                  label: 'Any Alarm',
                  required: true,
                  value: c.alartm.value,
                  onChanged: (v) => c.alartm.value = v),
              if (c.isRefer) ...[
                const SizedBox(height: 10),
                LabeledTextField(
                  label: 'Set Temp',
                  required: true,
                  controller: c.setTempController,
                  keyboardType: TextInputType.number,
                  hint: '°F',
                ),
                const SizedBox(height: 14),
                LabeledTextField(
                  label: 'Running Temp',
                  required: true,
                  controller: c.runningTempController,
                  keyboardType: TextInputType.number,
                  hint: '°F',
                ),
              ],
            ],
            if (c.isEmptyTrailer) ...[
              const SizedBox(height: 14),
              _groupHeader('Load Details'),
              CompactYesNoToggle(
                  label: 'Load Locks',
                  required: true,
                  value: c.loadLocks.value,
                  onChanged: (v) => c.loadLocks.value = v),
            ],
          ],
        ],
      ),
    );
  }

  Widget _deliverySection() {
    final c = _controller;
    return SectionCard(
      title: 'Delivery Schedule',
      subtitle: c.deliveryDistanceMiles.value == null
          ? 'Select an address to auto-calculate departure time'
          : null,
      icon: Icons.route_rounded,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressAutocompleteField(
            label: 'Delivery Address',
            required: true,
            controller: c.deliveryAddressController,
            onPlaceSelected: c.applyPlaceDetails,
          ),
          Obx(() {
            final label = c.routeInfoLabel;
            if (label == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.route_rounded, size: 16, color: _accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          LabeledDateTimeField(
            label: 'Deliver At',
            required: true,
            value: c.deliverAt.value,
            onChanged: c.setDeliverAt,
          ),
          const SizedBox(height: 14),
          LabeledDateTimeField(
            label: 'Departure At (auto-calculated, editable)',
            value: c.departureAt.value,
            onChanged: (dt) => c.departureAt.value = dt,
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
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverMultiSelectField(
            label: 'Driver(s)',
            drivers: c.drivers,
            selectedIds: c.selectedDriverIds,
            onChanged: (ids) => c.selectedDriverIds.value = ids,
          ),
          const SizedBox(height: 14),
          YesNoToggle(
              label: 'Log Book OK?',
              value: c.logBookOk.value,
              onChanged: (v) => c.logBookOk.value = v),
          if (c.logBookOk.value == 'no') ...[
            const SizedBox(height: 14),
            LabeledDropdown<String>(
              label: 'Log Book Remark',
              value: c.logBookRemark.value,
              options: const ['Not provided by driver', 'Lost'],
              labelBuilder: (v) => v,
              onChanged: (v) => c.logBookRemark.value = v,
            ),
          ],
          const SizedBox(height: 14),
          YesNoToggle(
              label: 'Fuel Card',
              value: c.fuelCard.value,
              onChanged: (v) => c.fuelCard.value = v),
          if (c.fuelCard.value == 'no') ...[
            const SizedBox(height: 14),
            LabeledTextField(
              label: 'Fuel Card Remark',
              controller: c.fuelCardRemarkController,
              hint: 'What happened to the fuel card?',
            ),
          ],
          const SizedBox(height: 14),
          LabeledTextField(
            label: 'Description',
            controller: c.descriptionController,
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
                    if (!await _runTrailerReadinessCheck()) return;
                    final success = await _controller.submit();
                    if (success && mounted) {
                      Get.off(() => VehicleEntryListView(status: widget.status));
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
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
                : Text(
                    'Submit ${widget.status.label}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ));
  }
}
