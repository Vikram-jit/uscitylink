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

  String _fmt(DateTime d) => DateFormat('MMM dd, yyyy').format(d.toUtc());

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
    final range = await showDialog<DateTimeRange>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _DualMonthRangePicker(
          initialStart: _controller.filterStartDate.value,
          initialEnd: _controller.filterEndDate.value,
        ),
      ),
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
            onPrimary: Colors.white,
            surface: const Color(0xFF1C1C2E),
            onSurface: Colors.white,
            // M3 uses onSurfaceVariant for nav arrows and secondary text
            onSurfaceVariant: Colors.white70,
            surfaceContainerHighest: const Color(0xFF2A2A3E),
            outline: Colors.white24,
          ),
          // make < > arrows white
          iconTheme: const IconThemeData(color: Colors.white),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(foregroundColor: Colors.white),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1C1C2E),
          ),
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

// ─────────────────────────────────────────────────────────────
//  Enterprise dual-month date range picker
// ─────────────────────────────────────────────────────────────

// Each day cell is a fixed square; the month panel is exactly 7 × _kCell wide.
// This removes all `Expanded` usage from the grid so both calendars always
// render side-by-side at the correct size regardless of dialog constraints.
const double _kCell = 36.0;
const Color _kRangeBg = Color(0xFF1E3358); // range band colour

class _DualMonthRangePicker extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _DualMonthRangePicker({this.initialStart, this.initialEnd});

  @override
  State<_DualMonthRangePicker> createState() => _DualMonthRangePickerState();
}

class _DualMonthRangePickerState extends State<_DualMonthRangePicker> {
  late DateTime _leftMonth;
  DateTime? _start;
  DateTime? _end;
  DateTime? _hovered;

  // panel width = 7 fixed cells; dialog = 2 panels + gap + padding
  static const _panelW = _kCell * 7; // 252
  static const _dialogW = _panelW * 2 + 80 + 1; // ~585

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    final now = DateTime.now();
    _leftMonth = DateTime(now.year, now.month - 1);
  }

  DateTime get _rightMonth =>
      DateTime(_leftMonth.year, _leftMonth.month + 1);

  // ── Navigation ──

  void _prevMonth() =>
      setState(() => _leftMonth = DateTime(_leftMonth.year, _leftMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final right = _rightMonth;
    if (right.year < now.year ||
        (right.year == now.year && right.month < now.month)) {
      setState(() =>
          _leftMonth = DateTime(_leftMonth.year, _leftMonth.month + 1));
    }
  }

  // ── Selection ──

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else if (_sameDay(day, _start!)) {
          // tapping same day = single-day range
          _end = day;
        } else {
          _end = day;
        }
      }
      _hovered = null;
    });
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _start = start;
      _end = end;
      _hovered = null;
      // Navigate so end date's month is the right panel
      _leftMonth = DateTime(end.year, end.month - 1);
    });
  }

  // ── Range helpers ──

  DateTime? get _effectiveEnd => _end ?? (_start != null ? _hovered : null);

  bool _inRange(DateTime day) {
    if (_start == null || _effectiveEnd == null) return false;
    final lo = _start!.isBefore(_effectiveEnd!) ? _start! : _effectiveEnd!;
    final hi = _start!.isBefore(_effectiveEnd!) ? _effectiveEnd! : _start!;
    return day.isAfter(lo) && day.isBefore(hi);
  }

  bool _isStart(DateTime d) => _start != null && _sameDay(d, _start!);

  bool _isEnd(DateTime d) {
    final eff = _effectiveEnd;
    return eff != null && _sameDay(d, eff) && !_sameDay(d, _start ?? d);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isFuture(DateTime d) {
    final today = DateTime.now();
    return d.isAfter(DateTime(today.year, today.month, today.day));
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final canApply = _start != null && _end != null;
    final now = DateTime.now();
    final canNext = _rightMonth.year < now.year ||
        (_rightMonth.year == now.year && _rightMonth.month < now.month);

    return Container(
      width: _dialogW,
      decoration: BoxDecoration(
        color: _kBarBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderIdle),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 32,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(canNext),
          const _Divider(),
          _buildCalendars(),
          const _Divider(),
          _buildSelectionBar(),
          const _Divider(),
          _buildFooter(canApply),
        ],
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(bool canNext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, size: 16, color: _kAccent),
          const SizedBox(width: 8),
          Text('Select Date Range',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const Spacer(),
          // Month navigation
          _NavIcon(Icons.chevron_left_rounded, onTap: _prevMonth),
          const SizedBox(width: 4),
          _NavIcon(Icons.chevron_right_rounded,
              onTap: canNext ? _nextMonth : null),
          const SizedBox(width: 8),
          _NavIcon(Icons.close_rounded,
              size: 14,
              color: Colors.white54,
              onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  // ── Two-month grid ──

  Widget _buildCalendars() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _monthPanel(_leftMonth),
          const SizedBox(width: 19),
          Container(width: 1, height: 260, color: const Color(0xFF222235)),
          const SizedBox(width: 20),
          _monthPanel(_rightMonth),
        ],
      ),
    );
  }

  Widget _monthPanel(DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return SizedBox(
      width: _panelW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month title
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                DateFormat('MMMM  yyyy').format(month),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Day-of-week header
          Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => SizedBox(
                      width: _kCell,
                      height: 22,
                      child: Center(
                        child: Text(d,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white30,
                                letterSpacing: 0.5)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 2),
          // Day rows
          for (int row = 0; row < rows; row++)
            Row(
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                if (idx < firstWeekday ||
                    idx >= firstWeekday + daysInMonth) {
                  return SizedBox(width: _kCell, height: _kCell);
                }
                final day = DateTime(
                    month.year, month.month, idx - firstWeekday + 1);
                return _dayCell(day);
              }),
            ),
        ],
      ),
    );
  }

  // ── Day cell with half-bar range highlight ──

  Widget _dayCell(DateTime day) {
    final isStart = _isStart(day);
    final isEnd = _isEnd(day);
    final inRange = _inRange(day);
    final future = _isFuture(day);
    final today = _sameDay(day, DateTime.now());
    final selected = isStart || isEnd;
    final hasRange = _effectiveEnd != null &&
        !_sameDay(_start!, _effectiveEnd!);

    return MouseRegion(
      cursor: future
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (_start != null && _end == null && !future) {
          setState(() => _hovered = day);
        }
      },
      onExit: (_) {
        if (_hovered != null) setState(() => _hovered = null);
      },
      child: GestureDetector(
        onTap: future ? null : () => _onDayTap(day),
        child: SizedBox(
          width: _kCell,
          height: _kCell,
          child: Stack(
            children: [
              // ── Range band fills full height ──
              if (inRange)
                Positioned.fill(
                    child: Container(color: _kRangeBg)),
              // Start cell: right-half band connects to range
              if (isStart && hasRange)
                Positioned(
                    left: _kCell / 2, right: 0, top: 0, bottom: 0,
                    child: Container(color: _kRangeBg)),
              // End cell: left-half band connects from range
              if (isEnd && hasRange)
                Positioned(
                    right: _kCell / 2, left: 0, top: 0, bottom: 0,
                    child: Container(color: _kRangeBg)),

              // ── Selection pill (start / end) ──
              if (selected)
                Positioned(
                  left: 3, right: 3, top: 3, bottom: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

              // ── Today outline ──
              if (today && !selected)
                Positioned(
                  left: 3, right: 3, top: 3, bottom: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _kAccent.withValues(alpha: 0.55),
                          width: 1.5),
                    ),
                  ),
                ),

              // ── Day number ──
              Center(
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? Colors.white
                        : future
                            ? Colors.white12
                            : inRange
                                ? Colors.white70
                                : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selection summary bar ──

  Widget _buildSelectionBar() {
    final fmt = DateFormat('MMM dd, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Presets
          Wrap(
            spacing: 6,
            children: [
              _Preset('Today', () {
                final d = DateTime.now();
                _applyPreset(DateTime(d.year, d.month, d.day),
                    DateTime(d.year, d.month, d.day));
              }),
              _Preset('Last 7 Days', () {
                final end = DateTime.now();
                _applyPreset(
                    end.subtract(const Duration(days: 6)), end);
              }),
              _Preset('This Month', () {
                final now = DateTime.now();
                _applyPreset(DateTime(now.year, now.month, 1), now);
              }),
              _Preset('Last Month', () {
                final now = DateTime.now();
                final first =
                    DateTime(now.year, now.month - 1, 1);
                final last = DateTime(now.year, now.month, 0);
                _applyPreset(first, last);
              }),
            ],
          ),
          const Spacer(),
          // From → To
          _DateBox(
            label: 'From',
            value: _start != null ? fmt.format(_start!) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.arrow_forward_rounded,
                size: 13,
                color: _start != null && _end != null
                    ? _kAccent
                    : Colors.white24),
          ),
          _DateBox(
            label: 'To',
            value: _end != null ? fmt.format(_end!) : null,
            hint: _start != null ? 'pick end' : null,
          ),
        ],
      ),
    );
  }

  // ── Footer ──

  Widget _buildFooter(bool canApply) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
            child:
                Text('Cancel', style: GoogleFonts.poppins(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: canApply ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 180),
            child: ElevatedButton.icon(
              onPressed: canApply
                  ? () => Navigator.of(context)
                      .pop(DateTimeRange(start: _start!, end: _end!))
                  : null,
              icon: const Icon(Icons.check_rounded, size: 14),
              label: Text('Apply Range',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                disabledBackgroundColor: _kAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Small reusable helpers (private to this file)
// ─────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: Color(0xFF1E1E30), height: 1);
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const _NavIcon(this.icon,
      {this.onTap,
      this.size = 16,
      this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.07 : 0.02),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: enabled ? _kBorderIdle : Colors.white12),
        ),
        child: Icon(icon,
            size: size,
            color: enabled ? color : Colors.white24),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;

  const _DateBox({required this.label, this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: value != null
            ? _kChipBg
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: value != null
                ? _kAccent.withValues(alpha: 0.4)
                : _kBorderIdle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(
            value ?? hint ?? '—',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: value != null
                  ? Colors.white
                  : hint != null
                      ? Colors.white38
                      : Colors.white24,
              fontWeight:
                  value != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Preset extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _Preset(this.label, this.onTap);

  @override
  State<_Preset> createState() => _PresetState();
}

class _PresetState extends State<_Preset> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? _kAccent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: _hovered
                    ? _kAccent.withValues(alpha: 0.5)
                    : _kBorderIdle),
          ),
          child: Text(widget.label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color:
                      _hovered ? _kAccent : Colors.white54,
                  fontWeight: _hovered
                      ? FontWeight.w600
                      : FontWeight.w400)),
        ),
      ),
    );
  }
}
