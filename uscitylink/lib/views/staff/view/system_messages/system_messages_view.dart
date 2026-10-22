import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/staff/system_message_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

final _timeFormat = DateFormat('dd MMM yyyy, hh:mm a');

/// System messages (yard gate events) — same features as the web "System Messages" page.
class SystemMessagesView extends StatefulWidget {
  const SystemMessagesView({super.key});

  @override
  State<SystemMessagesView> createState() => _SystemMessagesViewState();
}

class _SystemMessagesViewState extends State<SystemMessagesView> {
  final SystemMessageController _controller = Get.put(SystemMessageController());
  final ScrollController _scroll = ScrollController();
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    _controller.load();
    _controller.loadStaff();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) _controller.loadMore();
    });
    // Like the web page: unread messages pop up shortly after the screen opens
    _controller.loadUnread().then((_) {
      _popupTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _controller.unread.isNotEmpty) _showUnreadSheet();
      });
    });
  }

  @override
  void dispose() {
    _popupTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Mark completed; if no matching gate log exists the server asks for a note first.
  Future<void> _complete(SystemMessage message) async {
    final result = await _controller.complete(message);
    if (!result.requiresNote || !mounted) return;
    final note = await askForNote(
      context,
      title: 'No matching gate log found',
      explanation: result.message,
      label: 'Note',
      hint: 'Explain why this message is being completed without a matching gate log…',
      confirmLabel: 'Complete with note',
      confirmColor: StaffColors.success,
      minLength: SystemMessageController.minNoteLength,
    );
    if (note != null) await _controller.complete(message, note: note);
  }

  void _showUnreadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => Obx(() {
          final unread = _controller.unread;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unread system messages', style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
                          Text('Uncompleted messages must be marked one by one.',
                              style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              const Divider(height: 1, color: StaffColors.hairline),
              Expanded(
                child: unread.isEmpty
                    ? Center(child: Text('All messages completed.', style: AppText.bodyMd.copyWith(color: StaffColors.textMuted)))
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount: unread.length,
                        separatorBuilder: (_, __) => const Divider(color: StaffColors.hairline),
                        itemBuilder: (ctx, i) {
                          final m = unread[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.timestamp == null ? '' : _timeFormat.format(m.timestamp!),
                                        style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(m.body, style: AppText.bodyMd.copyWith(color: StaffColors.textStrong)),
                                    if (m.isCompleted)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: StaffPill(
                                            label: 'Completed by ${m.completedByName ?? 'someone'}', color: StaffColors.success),
                                      ),
                                    if (m.note != null)
                                      Text('Note: ${m.note}', style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Obx(() => FilledButton(
                                    onPressed: _controller.markingId.value == m.id ? null : () => _complete(m),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: m.isCompleted ? StaffColors.primary : StaffColors.success,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text(m.isCompleted ? 'Mark read' : 'Mark completed'),
                                  )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _pickStaff() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (ctx) => SafeArea(
        child: Obx(() => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: Text('Completed by', style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
                ),
                _staffOption(ctx, '', 'All staff'),
                for (final u in _controller.staff) _staffOption(ctx, u.id, u.name),
              ],
            )),
      ),
    );
  }

  Widget _staffOption(BuildContext ctx, String id, String name) {
    final selected = _controller.completedBy.value == id;
    return ListTile(
      leading: StaffAvatar(name: id.isEmpty ? 'All' : name, icon: id.isEmpty ? Icons.groups_rounded : null, size: 36),
      title: Text(name),
      trailing: selected ? const Icon(Icons.check_rounded, color: StaffColors.primary) : null,
      onTap: () {
        Navigator.pop(ctx);
        _controller.setCompletedBy(id);
      },
    );
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _controller.startDate.value.isEmpty
          ? null
          : DateTimeRange(
              start: DateTime.parse(_controller.startDate.value),
              end: DateTime.parse(_controller.endDate.value.isEmpty ? _controller.startDate.value : _controller.endDate.value),
            ),
    );
    if (range != null) _controller.setDates(fmt.format(range.start), fmt.format(range.end));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        body: Column(
          children: [
            StaffHeader(
              title: 'System messages',
              subtitle: 'Yard gate events to confirm',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
              actions: [
                Obx(() {
                  final count = _controller.unread.length;
                  return Badge(
                    isLabelVisible: count > 0,
                    backgroundColor: StaffColors.danger,
                    label: Text('$count'),
                    child: StaffGlassButton(icon: Icons.mark_email_unread_rounded, tooltip: 'Unread', onTap: _showUnreadSheet),
                  );
                }),
              ],
              bottom: StaffSearchField(
                controller: _controller.searchController,
                onChanged: _controller.onSearchChanged,
                hint: 'Search messages…',
              ),
            ),
            Obx(() {
              final staffName = _controller.staff.firstWhereOrNull((s) => s.id == _controller.completedBy.value)?.name;
              final dates = _controller.startDate.value.isEmpty
                  ? null
                  : '${_controller.startDate.value}${_controller.endDate.value.isNotEmpty && _controller.endDate.value != _controller.startDate.value ? ' → ${_controller.endDate.value}' : ''}';
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, 0),
                child: Row(
                  children: [
                    _filterChip(Icons.person_rounded, staffName == null ? 'Completed by: All' : 'By $staffName', staffName != null, _pickStaff),
                    const SizedBox(width: AppSpacing.sm),
                    _filterChip(Icons.date_range_rounded, dates ?? 'Any date', dates != null, _pickDates),
                    if (_controller.hasFilters) ...[
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: _controller.clearFilters,
                        style: TextButton.styleFrom(foregroundColor: StaffColors.danger),
                        child: const Text('Clear filters'),
                      ),
                    ],
                  ],
                ),
              );
            }),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: () async {
                  await Future.wait([_controller.load(), _controller.loadUnread()]);
                },
                child: Obx(() {
                  final messages = _controller.messages;
                  if (_controller.loading.value && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
                  }
                  if (messages.isEmpty) {
                    return const StaffEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No system messages found',
                      message: 'Truck arrivals and departures from the yard appear here.',
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xxl),
                    itemCount: messages.length + (_controller.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.base),
                          child: Center(child: CircularProgressIndicator(color: StaffColors.primary)),
                        );
                      }
                      return _messageCard(messages[i]);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(IconData icon, String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? StaffColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: active ? StaffColors.primary : StaffColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : StaffColors.textBody),
              const SizedBox(width: 6),
              Text(label, style: AppText.labelLg.copyWith(color: active ? Colors.white : StaffColors.textBody)),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: active ? Colors.white : StaffColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageCard(SystemMessage m) {
    final mediaUrl = m.url == null ? null : '${Constant.aws}/${m.url}';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
        border: Border(left: BorderSide(color: m.isCompleted ? StaffColors.success : StaffColors.warning, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              m.isCompleted
                  ? StaffPill(label: 'Completed by ${m.completedByName ?? 'someone'}', color: StaffColors.success, icon: Icons.check_rounded)
                  : const StaffPill(label: 'Pending', color: StaffColors.warning, icon: Icons.schedule_rounded),
              const Spacer(),
              Text(m.timestamp == null ? '' : _timeFormat.format(m.timestamp!),
                  style: AppText.labelMd.copyWith(color: StaffColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(m.body.isEmpty ? '-' : m.body, style: AppText.bodyMd.copyWith(color: StaffColors.textStrong))),
              if (mediaUrl != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _openMedia(mediaUrl, m.isImage),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: m.isImage
                        ? Image.network(mediaUrl, width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fileTile())
                        : _fileTile(),
                  ),
                ),
              ],
            ],
          ),
          if (m.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: StaffColors.canvas, borderRadius: BorderRadius.circular(AppRadii.sm)),
              child: Text('Note: ${m.note}', style: AppText.bodySm.copyWith(color: StaffColors.textBody)),
            ),
          ],
          if (!m.isCompleted)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Obx(() {
                  final marking = _controller.markingId.value == m.id;
                  return FilledButton.icon(
                    onPressed: marking ? null : () => _complete(m),
                    icon: marking
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('Mark completed'),
                    style: FilledButton.styleFrom(backgroundColor: StaffColors.success),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileTile() => Container(
        width: 56,
        height: 56,
        color: StaffColors.canvas,
        child: const Icon(Icons.insert_drive_file_outlined, color: StaffColors.textMuted),
      );

  void _openMedia(String url, bool isImage) {
    if (!isImage) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.base),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
