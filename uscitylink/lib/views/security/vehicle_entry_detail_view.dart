import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart';
import 'package:uscitylink/model/security/security_entry_detail.dart';
import 'package:uscitylink/services/security/security_entry_service.dart';
import 'package:uscitylink/utils/utils.dart';
import 'widgets/checklist_grid.dart';
import 'widgets/detail_row.dart';
import 'widgets/section_card.dart';

class VehicleEntryDetailView extends StatefulWidget {
  final int entryId;
  final VehicleEntryStatus status;

  const VehicleEntryDetailView(
      {super.key, required this.entryId, required this.status});

  @override
  State<VehicleEntryDetailView> createState() =>
      _VehicleEntryDetailViewState();
}

class _VehicleEntryDetailViewState extends State<VehicleEntryDetailView> {
  final _entryService = SecurityEntryService();
  bool _loading = true;
  SecurityEntryDetail? _entry;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final response = await _entryService.getEntryDetail(widget.entryId);
      setState(() {
        _entry = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Utils.snackBar('Error', e.toString());
    }
  }

  Color get _accentColor => widget.status == VehicleEntryStatus.entry
      ? const Color(0xFF16A34A)
      : const Color(0xFFDC2626);

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  String _yesNo(String? v) {
    if (v == null || v.isEmpty) return '—';
    return v == 'yes' ? 'Yes' : (v == 'no' ? 'No' : v);
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
            '${widget.status.label} Details',
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
        body: _loading
            ? Center(child: CircularProgressIndicator(color: _accentColor))
            : _entry == null
                ? Center(
                    child: Text('Entry not found.',
                        style: TextStyle(color: Colors.grey.shade500)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryCard(_entry!),
                        const SizedBox(height: 16),
                        _truckSection(_entry!),
                        if (_entry!.hasTrailer) ...[
                          const SizedBox(height: 16),
                          _trailerSection(_entry!),
                          if (_entry!.isLoaded && _entry!.delivery != null) ...[
                            const SizedBox(height: 16),
                            _deliverySection(_entry!),
                          ],
                        ],
                        const SizedBox(height: 16),
                        _notesSection(_entry!),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  bool _blank(String? v) => v == null || v.trim().isEmpty;

  Widget _summaryCard(SecurityEntryDetail e) {
    final vehicleLabel = [
      if (!_blank(e.truckNumber)) 'Truck ${e.truckNumber}',
      if (!_blank(e.trailerNumber)) 'Trailer ${e.trailerNumber}',
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
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.status == VehicleEntryStatus.entry
                  ? Icons.login_rounded
                  : Icons.logout_rounded,
              color: _accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleLabel.isEmpty ? 'Vehicle Entry' : vehicleLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fmtDateTime(e.createdAt ?? e.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          DetailBadge(
            text: widget.status == VehicleEntryStatus.entry ? 'Entry' : 'Departed',
            color: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _truckSection(SecurityEntryDetail e) {
    final checklist = <ChecklistItem>[
      ChecklistItem('Truck Key Attached', e.truckKeyAttached),
      ChecklistItem('Truck Matt', e.truckMatt),
      ChecklistItem('Log Book Stand', e.logBookStand),
      ChecklistItem('Did Security Guard Inspect', e.securityGuardInspect),
    ];

    return SectionCard(
      title: 'Truck Details',
      icon: Icons.local_shipping_rounded,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRow(label: 'Truck Number', value: e.truckNumber),
          DetailRow(label: 'Truck Fuel', value: e.truckFuel),
          DetailRow(label: 'Truck License Plate', value: e.truckLicensePlate),
          DetailRow(label: 'Security Guard', value: e.security),
          const SizedBox(height: 10),
          ChecklistGrid(items: checklist),
        ],
      ),
    );
  }

  Widget _trailerSection(SecurityEntryDetail e) {
    final checklist = <ChecklistItem>[
      ChecklistItem('Spare Tyre', e.spareTyre),
      ChecklistItem('Fire Ext.', e.fireExt),
      ChecklistItem('Warning Triangles', e.warningTriangles),
      ChecklistItem('Paper Work', e.paperWork),
      ChecklistItem('Damage', e.damage),
      // Kept for older entries that still have these set — no longer
      // collected on new submissions (replaced by Paper Work).
      if (!_blank(e.anualInspection)) ChecklistItem('Annual Inspection', e.anualInspection),
      if (!_blank(e.registration)) ChecklistItem('Registration', e.registration),
      if (e.isLoaded) ...[
        ChecklistItem('Seal', e.seal),
        ChecklistItem('Any Alarm', e.alartm),
      ],
      if (e.emptyLoaded == 'empty') ChecklistItem('Load Locks', e.loadLocks),
    ];

    return SectionCard(
      title: 'Trailer & Inspection',
      icon: Icons.rv_hookup_rounded,
      accentColor: _accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRow(label: 'Trailer Number', value: e.trailerNumber),
          DetailRow(label: 'Trailer Fuel', value: e.trailerFuel),
          DetailRow(label: 'Trailer License Plate', value: e.trailerLicensePlate),
          DetailRow(
            label: 'Empty or Loaded',
            valueWidget: DetailBadge(
              text: e.isLoaded ? 'Loaded' : 'Empty',
              color: e.isLoaded
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF6B7280),
            ),
          ),
          if (e.isLoaded) ...[
            DetailRow(
                label: 'Load Type',
                value: e.loadType == 'refer' ? 'Refer' : 'Dry'),
            if (e.loadType == 'refer') ...[
              DetailRow(label: 'Set Temp', value: e.setTemp),
              DetailRow(label: 'Running Temp', value: e.runningTemp),
            ],
          ],
          const SizedBox(height: 6),
          ChecklistGrid(items: checklist),
          if (e.damage == 'yes' && !_blank(e.damageDescription)) ...[
            const SizedBox(height: 10),
            DetailRow(label: 'Damage Description', value: e.damageDescription),
          ],
        ],
      ),
    );
  }

  Widget _deliverySection(SecurityEntryDetail e) {
    final d = e.delivery!;
    final address = [d.address, d.city, d.state, d.zipcode]
        .where((v) => (v ?? '').isNotEmpty)
        .join(', ');
    return SectionCard(
      title: 'Delivery Schedule',
      subtitle: d.distanceMiles != null
          ? '${d.distanceMiles!.toStringAsFixed(1)} mi from yard'
          : null,
      icon: Icons.route_rounded,
      accentColor: _accentColor,
      child: Column(
        children: [
          if (address.isNotEmpty) DetailRow(label: 'Delivery Address', value: address),
          DetailRow(label: 'Deliver At', value: _fmtDateTime(d.deliverAt)),
          DetailRow(label: 'Departure At', value: _fmtDateTime(d.departureAt)),
        ],
      ),
    );
  }

  Widget _notesSection(SecurityEntryDetail e) {
    return SectionCard(
      title: 'Notes & Sign-off',
      icon: Icons.edit_note_rounded,
      accentColor: _accentColor,
      child: Column(
        children: [
          if (!_blank(e.driverNames))
            DetailRow(label: 'Driver(s)', value: e.driverNames),
          if (!_blank(e.logBookRemark))
            DetailRow(label: 'Log Book Remark', value: e.logBookRemark),
          DetailRow(label: 'Fuel Card', value: _yesNo(e.fuelCard)),
          if (e.fuelCard == 'no' && !_blank(e.fuelCardRemark))
            DetailRow(label: 'Fuel Card Remark', value: e.fuelCardRemark),
          if (!_blank(e.description))
            DetailRow(label: 'Description', value: e.description),
        ],
      ),
    );
  }
}
