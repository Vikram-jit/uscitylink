import 'package:chat_app/modules/home/controllers/message_controller.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/widgets/file_viewer_gallery.dart';
import 'package:chat_app/widgets/media_component.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum MediaGallerySource { channel, group }

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
const _kBarBg = Color(0xFF12121F);
const _kAccent = Color(0xFF5B8DEF);
const _kChipBg = Color(0xFF1E2A42);
const _kBorderIdle = Color(0xFF2E2E45);

class MediaGallery extends StatefulWidget {
  final MediaGallerySource source;
  const MediaGallery({super.key, required this.source});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  late final MessageController _controller;
  late final HomeController _homeController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MessageController>();
    _homeController = Get.find<HomeController>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll ──

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_controller.isLoading.value &&
        _controller.hasMoreMedia.value) {
      _controller.loadMoreMedia(_userId, widget.source);
    }
  }

  Future<void> _onRefresh() async {
    _controller.media.clear();
    _controller.currentMediaPage = 1;
    _controller.hasMoreMedia.value = true;
    await _controller.fetchMedia(_userId, 1, widget.source);
  }

  // ── Helpers ──

  String get _userId => widget.source == MediaGallerySource.channel
      ? _homeController.driverId.value
      : _homeController.groupId.value;

  String _fmt(DateTime d) => DateFormat('MMM dd, yyyy').format(d);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Pickers ──

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.filterStartDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: _darkDateTheme,
    );
    if (picked == null) return;
    await _controller.applyMediaFilter(
      _userId,
      widget.source,
      startDate: picked,
      endDate: picked,
    );
  }

  Future<void> _pickDateRange() async {
    final s = _controller.filterStartDate.value;
    final e = _controller.filterEndDate.value;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          (s != null && e != null) ? DateTimeRange(start: s, end: e) : null,
      builder: _darkDateTheme,
    );
    if (range == null) return;
    await _controller.applyMediaFilter(
      _userId,
      widget.source,
      startDate: range.start,
      endDate: range.end,
    );
  }

  Widget _darkDateTheme(BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _kAccent,
            surface: const Color(0xFF1C1C2E),
            onSurface: Colors.white,
            onPrimary: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1C1C2E)),
        ),
        child: child!,
      );

  // ── Filter bar ──

  Widget _filterBar() {
    return Obx(() {
      final start = _controller.filterStartDate.value;
      final end = _controller.filterEndDate.value;
      final hasFilter = start != null;
      final isSingleDay = hasFilter && _isSameDay(start, end ?? DateTime(0));
      final isLoading = _controller.isLoading.value && _controller.media.isEmpty;

      final filterLabel = hasFilter
          ? (isSingleDay ? _fmt(start) : '${_fmt(start)}  –  ${_fmt(end!)}')
          : null;

      return Container(
        decoration: const BoxDecoration(
          color: _kBarBg,
          border: Border(
            bottom: BorderSide(color: Color(0xFF222235), width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 13, color: Colors.white38),
                const SizedBox(width: 5),
                Text(
                  'FILTER BY DATE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: _kAccent),
                  ),
                if (hasFilter && !isLoading) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        _controller.clearMediaFilter(_userId, widget.source),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 11, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),

            // ── Buttons + active chip ──
            Row(
              children: [
                _FilterBtn(
                  icon: Icons.today_outlined,
                  label: 'Single Day',
                  active: hasFilter && isSingleDay,
                  onTap: _pickSingleDate,
                ),
                const SizedBox(width: 8),
                _FilterBtn(
                  icon: Icons.date_range_outlined,
                  label: 'Date Range',
                  active: hasFilter && !isSingleDay,
                  onTap: _pickDateRange,
                ),

                // Animated chip
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: filterLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kChipBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _kAccent.withValues(alpha: 0.45)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSingleDay
                                      ? Icons.today_outlined
                                      : Icons.date_range_outlined,
                                  size: 13,
                                  color: _kAccent,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  filterLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value && _controller.media.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              );
            }

            if (_controller.media.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 52, color: Colors.grey.shade700),
                    const SizedBox(height: 10),
                    Text(
                      _controller.filterStartDate.value != null
                          ? 'No media for this date'
                          : 'No media yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: Colors.white,
              backgroundColor: Colors.grey.shade900,
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(2),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _controller.media[index];
                          return MediaComponent(
                            key: ValueKey(item.id),
                            initialIndex: index,
                            type: GallertType.Media,
                            messageId: item.id!,
                            url: item.key!,
                            fileName: item.fileName ?? '',
                            uploadType: item.uploadType ?? 'server',
                            messageDirection: item.userProfileId ==
                                    _homeController.driverId.value
                                ? 'R'
                                : 'S',
                            thumbnail: item.thumbnail,
                            createdAt: item.createdAt ?? '',
                          );
                        },
                        childCount: _controller.media.length,
                        findChildIndexCallback: (key) {
                          final id = (key as ValueKey).value;
                          final idx =
                              _controller.media.indexWhere((m) => m.id == id);
                          return idx == -1 ? null : idx;
                        },
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _controller.isLoading.value
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white38),
                                ),
                              ),
                            )
                          : _controller.hasMoreMedia.value
                              ? const SizedBox(height: 16)
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14, color: Colors.white24),
                                      const SizedBox(width: 6),
                                      Text(
                                        'All media loaded',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white24,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Filter button
// ─────────────────────────────────────────────────────────────
class _FilterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? _kAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _kAccent : _kBorderIdle,
            width: active ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(active),
                size: 14,
                color: active ? _kAccent : Colors.white54,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? _kAccent : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
