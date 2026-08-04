import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/vehicle_inspection_history_controller.dart';
import 'package:uscitylink/model/security/vehicle_inspection_history_item.dart';
import 'vehicle_inspection_detail_view.dart';
import 'vehicle_inspection_form_view.dart';

const Color _kAccentColor = Color(0xFF1B3B8C);

class VehicleInspectionHistoryView extends StatefulWidget {
  final String tab; // 'truck' | 'trailer'
  final int vehicleId;
  final String vehicleNumber;

  const VehicleInspectionHistoryView({
    super.key,
    required this.tab,
    required this.vehicleId,
    required this.vehicleNumber,
  });

  @override
  State<VehicleInspectionHistoryView> createState() =>
      _VehicleInspectionHistoryViewState();
}

class _VehicleInspectionHistoryViewState extends State<VehicleInspectionHistoryView> {
  late final String _tag;
  late final VehicleInspectionHistoryController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tag = '${widget.tab}_${widget.vehicleId}';
    _controller = Get.put(
        VehicleInspectionHistoryController(widget.tab, widget.vehicleId),
        tag: _tag);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<VehicleInspectionHistoryController>(tag: _tag);
    super.dispose();
  }

  String _dateLabel(String? iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final vehicleLabel =
        '${widget.tab == 'truck' ? 'Truck' : 'Trailer'} ${widget.vehicleNumber}';
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
          title: Text(
            vehicleLabel,
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
          actions: widget.tab == 'truck'
              ? [
                  TextButton.icon(
                    onPressed: () => Get.to(() => VehicleInspectionFormView(
                            initialTruckId: widget.vehicleId))
                        ?.then((_) => _controller.refreshHistory()),
                    icon: const Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('New',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ]
              : null,
        ),
        body: Obx(() {
          if (_controller.isLoading.value && _controller.inspections.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: _kAccentColor));
          }
          if (_controller.inspections.isEmpty) {
            return Center(
              child: Text('No inspections recorded for this vehicle yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            );
          }
          return RefreshIndicator(
            color: _kAccentColor,
            onRefresh: _controller.refreshHistory,
            child: ListView.builder(
              controller: _scrollController,
              physics:
                  const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: _controller.inspections.length + 1,
              itemBuilder: (context, index) {
                if (index == _controller.inspections.length) {
                  if (_controller.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: CircularProgressIndicator(color: _kAccentColor)),
                    );
                  }
                  return const SizedBox();
                }
                final inspection = _controller.inspections[index];
                return _InspectionRow(
                  inspection: inspection,
                  tab: widget.tab,
                  dateLabel: _dateLabel(inspection.inspectedAt),
                  onTap: () =>
                      Get.to(() => VehicleInspectionDetailView(inspectionId: inspection.id!)),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _InspectionRow extends StatelessWidget {
  final VehicleInspectionHistoryItem inspection;
  final String tab;
  final String dateLabel;
  final VoidCallback onTap;

  const _InspectionRow({
    required this.inspection,
    required this.tab,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pairedVehicle = tab == 'truck' ? inspection.trailerNumber : inspection.truckNumber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      dateLabel,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if ((inspection.driverNames ?? '').isNotEmpty)
                      Text(
                        inspection.driverNames!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    if ((pairedVehicle ?? '').isNotEmpty)
                      Text(
                        '${tab == 'truck' ? 'Trailer' : 'Truck'} $pairedVehicle',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _countBadge('${inspection.okCount} OK', const Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        if (inspection.problemCount > 0)
                          _countBadge('${inspection.problemCount} Problem',
                              const Color(0xFFDC2626)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
