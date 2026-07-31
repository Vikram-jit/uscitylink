import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart';
import 'package:uscitylink/controller/vehicle_entry_list_controller.dart';
import 'package:uscitylink/model/security/security_entry_list_item.dart';
import 'vehicle_entry_detail_view.dart';

// Same overflow trick used across the module — the search card floats over
// the gradient header and needs the Stack's own bounds extended so it stays
// tappable (Positioned with a negative offset paints outside but can't be
// hit-tested there).
const double _kSearchCardHeight = 92;
const double _kSearchCardOverlap = 24;
const double _kSearchCardOverflow = _kSearchCardHeight - _kSearchCardOverlap;

class VehicleEntryListView extends StatefulWidget {
  final VehicleEntryStatus status;

  const VehicleEntryListView({super.key, required this.status});

  @override
  State<VehicleEntryListView> createState() => _VehicleEntryListViewState();
}

class _VehicleEntryListViewState extends State<VehicleEntryListView> {
  late final String _tag;
  late final VehicleEntryListController _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tag = widget.status.name;
    _controller = Get.put(VehicleEntryListController(widget.status), tag: _tag);
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
    Get.delete<VehicleEntryListController>(tag: _tag);
    super.dispose();
  }

  Color get _accentColor => widget.status == VehicleEntryStatus.entry
      ? const Color(0xFF16A34A)
      : const Color(0xFFDC2626);

  String get _title => widget.status == VehicleEntryStatus.entry
      ? 'Vehicle Entries'
      : 'Vehicle Departures';

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
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _Header(title: _title, accentColor: _accentColor),
                    const SizedBox(height: _kSearchCardOverflow),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: SizedBox(
                    height: _kSearchCardHeight,
                    child: _SearchCard(
                      hint: widget.status == VehicleEntryStatus.entry
                          ? 'Search truck or trailer number...'
                          : 'Search truck or trailer number...',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _kSearchCardOverflow - 60),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value && _controller.entries.isEmpty) {
                  return Center(
                      child: CircularProgressIndicator(color: _accentColor));
                }
                if (_controller.entries.isEmpty) {
                  return _EmptyState(
                    message: widget.status == VehicleEntryStatus.entry
                        ? 'No vehicle entries found.'
                        : 'No vehicle departures found.',
                  );
                }
                return RefreshIndicator(
                  color: _accentColor,
                  onRefresh: _controller.refreshEntries,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: _controller.entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _controller.entries.length) {
                        if (_controller.hasMore) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: _accentColor)),
                          );
                        }
                        return const SizedBox();
                      }
                      final entry = _controller.entries[index];
                      return _EntryCard(
                        entry: entry,
                        accentColor: _accentColor,
                        onTap: () => Get.to(() => VehicleEntryDetailView(
                              entryId: entry.id!,
                              status: widget.status,
                            )),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _Header({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 12, 20, 46),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accentColor, accentColor.withOpacity(0.8)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -50, right: -30, child: _orb(140, 0.08)),
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchCard({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final SecurityEntryListItem entry;
  final Color accentColor;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.accentColor,
    required this.onTap,
  });

  String get _dateLabel {
    final raw = entry.createdAt ?? entry.date;
    if (raw == null) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final hasTrailer = (entry.trailerNumber ?? '').isNotEmpty;
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
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping_rounded,
                    color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truck ${entry.truckNumber ?? '—'}'
                      '${hasTrailer ? ' • Trailer ${entry.trailerNumber}' : ''}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateLabel,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if ((entry.driverNames ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.driverNames!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                    if ((entry.emptyLoaded ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _StatusChip(text: entry.emptyLoaded == 'loaded'
                          ? 'Loaded'
                          : 'Empty'),
                    ],
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
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = text == 'Loaded'
        ? const Color(0xFF2563EB)
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
