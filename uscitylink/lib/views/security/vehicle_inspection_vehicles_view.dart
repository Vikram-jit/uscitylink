import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/vehicle_inspection_list_controller.dart';
import 'package:uscitylink/model/security/vehicle_inspection_list_item.dart';
import 'vehicle_inspection_form_view.dart';
import 'vehicle_inspection_history_view.dart';

const Color _kAccentColor = Color(0xFF1B3B8C);

class VehicleInspectionVehiclesView extends StatefulWidget {
  const VehicleInspectionVehiclesView({super.key});

  @override
  State<VehicleInspectionVehiclesView> createState() =>
      _VehicleInspectionVehiclesViewState();
}

class _VehicleInspectionVehiclesViewState
    extends State<VehicleInspectionVehiclesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.zero),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, topInset + 12, 20, 0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_kAccentColor, Color(0xFF13275C)],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Vehicle Inspections',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Trucks'),
                        Tab(text: 'Trailers'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _InspectionVehicleListTab(tab: 'truck'),
                  _InspectionVehicleListTab(tab: 'trailer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionVehicleListTab extends StatefulWidget {
  final String tab;

  const _InspectionVehicleListTab({required this.tab});

  @override
  State<_InspectionVehicleListTab> createState() => _InspectionVehicleListTabState();
}

class _InspectionVehicleListTabState extends State<_InspectionVehicleListTab>
    with AutomaticKeepAliveClientMixin {
  late final VehicleInspectionListController _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  static const _filters = [
    ('all', 'All'),
    ('never', 'Never Inspected'),
    ('within24', 'Within 24h'),
    ('older24', 'Over 24h'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller =
        Get.put(VehicleInspectionListController(widget.tab), tag: widget.tab);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.fetchMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.applySearch(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    Get.delete<VehicleInspectionListController>(tag: widget.tab);
    super.dispose();
  }

  String _dateLabel(String? iso) {
    if (iso == null) return 'Not Inspected Yet';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  /// Mirrors the web's Time Remaining column: inspected_at + 24h compared to
  /// now, formatted like Carbon's diffForHumans(parts: 2, short: true,
  /// syntax: DIFF_RELATIVE_TO_NOW) — "1d 5h from now" / "1w 6d ago".
  String? _timeRemainingLabel(String? iso) {
    if (iso == null) return null;
    final lastInspected = DateTime.tryParse(iso)?.toLocal();
    if (lastInspected == null) return null;
    final deadline = lastInspected.add(const Duration(hours: 24));
    final diff = deadline.difference(DateTime.now());
    final overdue = diff.isNegative;
    final duration = _humanizeDuration(diff.abs());
    return overdue ? '$duration ago' : '$duration from now';
  }

  /// Largest 2 non-zero units (weeks/days/hours/minutes) — same "2 parts"
  /// behavior as Carbon's diffForHumans.
  String _humanizeDuration(Duration d) {
    var minutes = d.inMinutes;
    final weeks = minutes ~/ (60 * 24 * 7);
    minutes -= weeks * 60 * 24 * 7;
    final days = minutes ~/ (60 * 24);
    minutes -= days * 60 * 24;
    final hours = minutes ~/ 60;
    minutes -= hours * 60;

    final parts = <String>[];
    if (weeks > 0) parts.add('${weeks}w');
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (parts.isEmpty) return '0m';
    return parts.take(2).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search ${widget.tab} number...',
                hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade500),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: Obx(() {
            // Read .value synchronously here — Obx only tracks observables
            // touched during this callback's own execution, not ones read
            // later inside ListView's lazily-invoked itemBuilder.
            final currentFilter = _controller.filter.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (value, label) = _filters[index];
                final selected = currentFilter == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => _controller.applyFilter(value),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                  selectedColor: _kAccentColor,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: selected ? _kAccentColor : Colors.grey.shade200),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value && _controller.vehicles.isEmpty) {
              return const Center(
                  child: CircularProgressIndicator(color: _kAccentColor));
            }
            if (_controller.vehicles.isEmpty) {
              return Center(
                child: Text('No ${widget.tab}s found.',
                    style: TextStyle(color: Colors.grey.shade500)),
              );
            }
            return RefreshIndicator(
              color: _kAccentColor,
              onRefresh: _controller.refreshVehicles,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: _controller.vehicles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _controller.vehicles.length) {
                    if (_controller.hasMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child:
                                CircularProgressIndicator(color: _kAccentColor)),
                      );
                    }
                    return const SizedBox();
                  }
                  final vehicle = _controller.vehicles[index];
                  return _VehicleRow(
                    vehicle: vehicle,
                    tab: widget.tab,
                    dateLabel: _dateLabel(vehicle.lastInspectedAt),
                    timeRemainingLabel: _timeRemainingLabel(vehicle.lastInspectedAt),
                    onTap: () => Get.to(() => VehicleInspectionHistoryView(
                          tab: widget.tab,
                          vehicleId: vehicle.id!,
                          vehicleNumber: vehicle.number ?? '',
                        )),
                    onNewInspection: widget.tab == 'truck'
                        ? () => Get.to(() =>
                            VehicleInspectionFormView(initialTruckId: vehicle.id))
                        : null,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final VehicleInspectionListItem vehicle;
  final String tab;
  final String dateLabel;
  final String? timeRemainingLabel;
  final VoidCallback onTap;
  final VoidCallback? onNewInspection;

  const _VehicleRow({
    required this.vehicle,
    required this.tab,
    required this.dateLabel,
    required this.timeRemainingLabel,
    required this.onTap,
    this.onNewInspection,
  });

  @override
  Widget build(BuildContext context) {
    final doneColor =
        vehicle.isDone ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final overdue = !vehicle.isDone && vehicle.lastInspectedAt != null;
    final hasCounts = vehicle.okCount > 0 || vehicle.problemCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent bar ties this card into the same "colored left edge"
            // language used by the checklist group cards — green while
            // within the 24h window, red once overdue.
            Container(width: 4, color: doneColor),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: doneColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tab == 'truck'
                                  ? Icons.local_shipping_rounded
                                  : Icons.rv_hookup_rounded,
                              color: doneColor,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${tab == 'truck' ? 'Truck' : 'Trailer'} ${vehicle.number ?? '—'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ),
                                    // Inspection Done (within 24 hours) —
                                    // matches the web's ✓/✗ column exactly.
                                    Icon(
                                      vehicle.isDone
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 17,
                                      color: doneColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                _infoRow('Last Inspected On', dateLabel,
                                    Colors.grey.shade600),
                                if (timeRemainingLabel != null) ...[
                                  const SizedBox(height: 3),
                                  _infoRow(
                                    'Time Remaining',
                                    overdue
                                        ? '$timeRemainingLabel (overdue)'
                                        : timeRemainingLabel!,
                                    overdue
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF16A34A),
                                  ),
                                ],
                                if (hasCounts) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _countBadge('${vehicle.okCount} OK',
                                          const Color(0xFF16A34A)),
                                      if (vehicle.problemCount > 0)
                                        _countBadge(
                                            '${vehicle.problemCount} Problem',
                                            const Color(0xFFDC2626)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: onNewInspection != null
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: onNewInspection,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('New Inspection',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700)),
                                style: TextButton.styleFrom(
                                  foregroundColor: _kAccentColor,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('View History',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade500)),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey.shade400, size: 18),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _infoRow(String label, String value, Color valueColor) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}
