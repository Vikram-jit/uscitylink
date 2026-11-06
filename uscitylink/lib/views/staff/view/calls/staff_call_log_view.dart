import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/staff/call_log_controller.dart';
import 'package:uscitylink/services/call/call_models.dart';
import 'package:uscitylink/services/call/call_service.dart';
import 'package:uscitylink/services/staff/call_log_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/calls/call_recording_player.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Staff → Call log: the same calls the web dashboard lists (who called, direction, status,
/// who answered, talk time), with a button to call the driver back.
class StaffCallLogView extends StatefulWidget {
  const StaffCallLogView({super.key, this.controller});

  /// For tests; the app creates its own.
  final CallLogController? controller;

  @override
  State<StaffCallLogView> createState() => _StaffCallLogViewState();
}

/// Same wording as the web dashboard (CallDetailDrawer.tsx).
const _statusLabel = {
  'completed': 'Answered',
  'missed': 'Missed',
  'cancelled': 'Missed',
  'declined': 'Declined',
  'busy': 'Busy',
  'failed': 'Failed',
  'ringing': 'Ringing',
  'ongoing': 'On call',
};

const _reasonLabel = {
  'caller_hung_up': 'Caller hung up',
  'callee_hung_up': 'Answerer hung up',
  'caller_cancelled': 'Caller hung up before it was answered',
  'no_answer': 'Nobody answered in time',
  'declined': 'Declined',
  'connection_lost': 'Connection lost',
  'queue_timeout': 'Waited too long in line — every dispatcher stayed busy',
  'no_dispatcher_online': 'No dispatcher was online',
  'busy': 'Driver was on another call',
  'unavailable': 'Nobody to ring',
};

const _outcomeLabel = {
  'answered': 'Answered',
  'declined': 'Declined',
  'missed': "Didn't answer",
  'left': 'Answered by someone else',
  'invited': 'Rang',
  'joined': 'Joined',
  'cancelled': 'Request taken back',
};

Color _statusColor(CallLogEntry c) =>
    c.status == 'completed' || c.status == 'ongoing'
        ? StaffColors.success
        : c.status == 'declined' || c.status == 'busy'
            ? StaffColors.warning
            : c.missed
                ? StaffColors.danger
                : StaffColors.textMuted;

String _when(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    return DateFormat('h:mm a').format(t);
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (t.year == yesterday.year &&
      t.month == yesterday.month &&
      t.day == yesterday.day) {
    return 'Yesterday ${DateFormat('h:mm a').format(t)}';
  }
  return DateFormat('MMM d, h:mm a').format(t);
}

class _StaffCallLogViewState extends State<StaffCallLogView>
    with SingleTickerProviderStateMixin {
  late final CallLogController _c =
      widget.controller ?? Get.put(CallLogController());
  late final TabController _tabs =
      TabController(length: CallLogController.filters.length, vsync: this);
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        _c.setFilter(CallLogController.filters.keys.elementAt(_tabs.index));
      }
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    if (widget.controller == null) Get.delete<CallLogController>();
    super.dispose();
  }

  void _callBack(CallLogEntry c, {bool video = false}) {
    if (!Get.isRegistered<CallService>() || c.driverId.isEmpty) return;
    CallService.to.startCall(
      driverId: c.driverId,
      name: c.driverName.isEmpty ? 'Driver' : c.driverName,
      subtitle: 'Driver',
      video: video,
    );
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
              title: 'Call log',
              subtitle: 'Every call with your drivers',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
              bottom: StaffSegmentedTabs(
                  controller: _tabs,
                  labels: CallLogController.filters.keys.toList()),
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: _c.load,
                child: Obx(() {
                  if (_c.loading.value && _c.calls.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: StaffColors.primary));
                  }
                  if (_c.error.value.isNotEmpty && _c.calls.isEmpty) {
                    return StaffEmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: "Couldn't load calls",
                        message: _c.error.value);
                  }
                  if (_c.calls.isEmpty) {
                    return StaffEmptyState(
                      icon: Icons.call_rounded,
                      title: _c.filter.value == 'All'
                          ? 'No calls yet'
                          : 'No ${_c.filter.value.toLowerCase()} calls',
                      message: 'Calls with drivers show up here.',
                    );
                  }
                  final more = _c.hasMore;
                  return ListView.separated(
                    key: const Key('callLogList'),
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                        AppSpacing.base, AppSpacing.base, AppSpacing.xxl),
                    itemCount: _c.calls.length + (more ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => i >= _c.calls.length
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.base),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: StaffColors.primary)),
                          )
                        : _CallRow(
                            call: _c.calls[i],
                            onTap: () => _details(_c.calls[i]),
                            onCall: () => _callBack(_c.calls[i]),
                          ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _details(CallLogEntry c) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
        builder: (ctx) => _CallDetailsSheet(
          call: c,
          detail: _c.detail(c.id),
          loadLink: () => _c.recordingLink(c.id),
          onCall: (video) {
            Navigator.pop(ctx);
            _callBack(c, video: video);
          },
        ),
      );
}

class _CallRow extends StatelessWidget {
  const _CallRow(
      {required this.call, required this.onTap, required this.onCall});

  final CallLogEntry call;
  final VoidCallback onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final c = call;
    final color = _statusColor(c);
    final status = _statusLabel[c.status] ?? c.status;
    final detail = [
      c.directionLabel,
      if (c.status == 'completed' && c.durationSec > 0)
        formatCallDuration(c.durationSec),
      if (c.answeredByName.isNotEmpty &&
          c.status == 'completed' &&
          c.fromDriver)
        c.answeredByName,
    ].join(' · ');
    return Material(
      color: StaffColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        key: Key('callLogRow-${c.id}'),
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                child: Icon(
                  c.missed
                      ? Icons.call_missed_rounded
                      : c.fromDriver
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverLabel(
                                c.driverName.isEmpty ? 'Driver' : c.driverName,
                                c.driverPhone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.titleMd.copyWith(
                                color: c.missed
                                    ? StaffColors.danger
                                    : StaffColors.textStrong),
                          ),
                        ),
                        if (c.type == 'video') ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.videocam_rounded,
                              size: 16, color: StaffColors.textMuted),
                        ],
                        if (c.recorded) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.fiber_manual_record,
                              size: 10, color: StaffColors.danger),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySm
                            .copyWith(color: StaffColors.textMuted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StaffPill(label: status, color: color),
                        Text(_when(c.startedAt),
                            style: AppText.labelMd
                                .copyWith(color: StaffColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('callLogCall-${c.id}'),
                tooltip:
                    'Call ${c.driverName.isEmpty ? 'driver' : c.driverName}',
                onPressed: c.driverId.isEmpty ? null : onCall,
                icon:
                    const Icon(Icons.call_rounded, color: StaffColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallDetailsSheet extends StatelessWidget {
  const _CallDetailsSheet(
      {required this.call,
      required this.detail,
      required this.loadLink,
      required this.onCall});

  final CallLogEntry call;
  final Future<CallLogDetail> detail;
  final Future<CallRecordingLink> Function() loadLink;
  final void Function(bool video) onCall;

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style:
                        AppText.bodySm.copyWith(color: StaffColors.textMuted))),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style:
                      AppText.bodyMd.copyWith(color: StaffColors.textStrong)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = call;
    final color = _statusColor(c);
    final status = c.status == 'cancelled'
        ? 'Missed (caller hung up)'
        : (_statusLabel[c.status] ?? c.status);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            Text(
                driverLabel(c.driverName.isEmpty ? 'Driver' : c.driverName,
                    c.driverPhone),
                style: AppText.titleLg.copyWith(color: StaffColors.textStrong)),
            const SizedBox(height: 2),
            Text(
                c.fromDriver
                    ? 'Called the dispatch line'
                    : '${c.initiatorName.isEmpty ? 'Dispatch' : c.initiatorName} called the driver',
                style: AppText.bodySm.copyWith(color: StaffColors.textMuted)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('callLogDetailCall'),
                    onPressed: c.driverId.isEmpty ? null : () => onCall(false),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(
                        backgroundColor: StaffColors.success),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: c.driverId.isEmpty ? null : () => onCall(true),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: StaffColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text('Status',
                    style:
                        AppText.bodySm.copyWith(color: StaffColors.textMuted)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: StaffPill(label: status, color: color)),
                ),
              ],
            ),
            _row('Direction', c.directionLabel),
            _row('Answered by',
                c.answeredByName.isEmpty ? '—' : c.answeredByName),
            _row(
                'Started',
                c.startedAt == null
                    ? '—'
                    : DateFormat('MMM d, y · h:mm:ss a').format(c.startedAt!)),
            _row('Time to answer',
                c.waitSec == null ? '—' : formatCallDuration(c.waitSec!)),
            if (c.queuedSec > 0)
              _row('Waited in line', formatCallDuration(c.queuedSec)),
            _row('Talk time', formatCallDuration(c.durationSec)),
            _row(
                'How it ended',
                _reasonLabel[c.endReason] ??
                    (c.endReason.isEmpty ? '—' : c.endReason)),
            const Divider(height: AppSpacing.xl),
            FutureBuilder<CallLogDetail>(
              future: detail,
              builder: (_, snap) {
                if (snap.hasError) {
                  return Text("Couldn't load the call details",
                      style:
                          AppText.bodySm.copyWith(color: StaffColors.danger));
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.base),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: StaffColors.primary)),
                  );
                }
                final rang = snap.data!.people
                    .where((p) => p.role == 'callee' || p.role == 'added')
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snap.data!.recording != null ||
                        c.status == 'completed') ...[
                      CallRecordingSection(
                        recording: snap.data!.recording,
                        answered: c.status == 'completed',
                        loadLink: loadLink,
                      ),
                      const Divider(height: AppSpacing.xl),
                    ],
                    if (rang.isNotEmpty)
                      Text(
                          'Rang ${rang.length} ${rang.length == 1 ? 'person' : 'people'}',
                          style: AppText.titleMd
                              .copyWith(color: StaffColors.textStrong)),
                    const SizedBox(height: AppSpacing.xs),
                    for (final p in rang)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(p.name,
                                  style: AppText.bodyMd
                                      .copyWith(color: StaffColors.textBody)),
                            ),
                            Text(
                              _outcomeLabel[p.outcome] ?? p.outcome,
                              style: AppText.labelMd.copyWith(
                                color: p.outcome == 'answered' ||
                                        p.outcome == 'joined'
                                    ? StaffColors.success
                                    : p.outcome == 'missed'
                                        ? StaffColors.danger
                                        : StaffColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
