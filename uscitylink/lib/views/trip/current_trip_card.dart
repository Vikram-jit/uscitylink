import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// Status colour shared by the trip card and the Loads list.
Color tripStatusColor(String status) => switch (status) {
      'completed' || 'routed' => TColors.brandGreen,
      'ended' || 'paperwork' => const Color(0xFF7C3AED),
      'cancelled' => Colors.grey,
      'on_hold' => Colors.redAccent,
      _ => TColors.navyHeaderDeep,
    };

/// The load the driver is on, its stops, and ONE big button for the next step
/// (Accept → Start trip → Arrived → Loaded, rolling → … → Delivered). Each tap goes to dispatch's
/// chat and the trip record. Hidden when there is no current trip.
///
/// Dashboard: the full card. Dispatch chat ([compact]): one line and the button, so the messages keep
/// their room; the header opens the full card (stops, Report problem, Undo).
class CurrentTripCard extends StatefulWidget {
  const CurrentTripCard({super.key, this.onOpenChat, this.onOpenLoads, this.service, this.compact = false});

  /// After delivery: open the dispatch chat to send the BOL / POD photos (none = already in the chat)
  final VoidCallback? onOpenChat;

  /// Dashboard: "All loads" in the header opens the Loads screen
  final VoidCallback? onOpenLoads;

  /// For tests; the app uses the registered TripService.
  final TripService? service;

  final bool compact;

  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _green = Color(0xFF16A34A);
  static const _amber = Color(0xFFB45309);

  @override
  State<CurrentTripCard> createState() => _CurrentTripCardState();

  static IconData _iconFor(String action) => switch (action) {
        'accept' => Icons.thumb_up_alt_rounded,
        'start' => Icons.play_arrow_rounded,
        'arrive' => Icons.place_rounded,
        'rolling' || 'depart' => Icons.route_rounded,
        'end' => Icons.flag_rounded,
        _ => Icons.check_rounded,
      };

  /// Only Delivered asks first (it closes the trip); Got it and Rolling are one tap (a wrong one can
  /// be undone for 5 minutes).
  static Future<void> _confirmThen(BuildContext context, TripStep step, Future<void> Function() go) async {
    if (step.action != 'end') return go();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(step.label),
        content: const Text('Dispatch is told the load is delivered. Then send the BOL / POD photos in the chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) await go();
  }

  static Future<void> _reportProblem(BuildContext context, TripService trips) async {
    const kinds = {
      'delay': 'Running late',
      'breakdown': 'Breakdown',
      'detention': 'Waiting at the dock (detention)',
      'lumper': 'Lumper',
      'rejected': 'Load rejected',
      'shortage': 'Shortage',
      'damage': 'Damage',
      'other': 'Something else',
    };
    var kind = 'delay';
    final note = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(c).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (c, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report a problem', style: AppText.titleMd),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in kinds.entries)
                    ChoiceChip(label: Text(e.value), selected: kind == e.key, onSelected: (_) => setState(() => kind = e.key)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What happened? (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Send to dispatch')),
              ),
            ],
          ),
        ),
      ),
    );
    if (send == true && await trips.reportProblem(kind, note.text.trim())) {
      Get.snackbar('Trip', 'Dispatch has been told', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
  }
}

class _CurrentTripCardState extends State<CurrentTripCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trips = widget.service ?? TripService.to;
    final compact = widget.compact;
    return Obx(() {
      final trip = trips.current.value;
      if (trip == null) return const SizedBox.shrink();
      final next = trip.next;
      final suggestion = trips.suggestion.value;
      final canUndo = (trips.undoUntil.value?.isAfter(DateTime.now()) ?? false);
      const muted = CurrentTripCard._muted;
      final color = tripStatusColor(trip.status);
      final full = !compact || _expanded;
      final nextStop = next?.stopId == null ? null : trip.stops.where((x) => x.id == next!.stopId).firstOrNull;

      return Padding(
        padding: EdgeInsets.only(bottom: compact ? AppSpacing.sm : AppSpacing.xl),
        child: Container(
          key: const Key('currentTripCard'),
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                key: const Key('tripCardHeader'),
                onTap: compact ? () => setState(() => _expanded = !_expanded) : null,
                child: Row(
                  children: [
                    Container(
                      width: compact ? 34 : 40,
                      height: compact ? 34 : 40,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.local_shipping_rounded, color: color, size: compact ? 18 : 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text('Trip #${trip.tripNo}', style: AppText.labelLg.copyWith(color: CurrentTripCard._ink, fontSize: 16)),
                    ),
                    _Pill(text: trip.statusLabel, color: color),
                    if (compact) Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: muted),
                    if (!compact && widget.onOpenLoads != null)
                      TextButton(
                        key: const Key('tripAllLoads'),
                        style: TextButton.styleFrom(foregroundColor: TColors.navyHeaderDeep, padding: const EdgeInsets.only(left: 8)),
                        onPressed: widget.onOpenLoads,
                        child: const Text('All loads ›'),
                      ),
                  ],
                ),
              ),
              // Collapsed (chat): just where the driver is heading next
              if (!full && nextStop != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    '${nextStop.typeLabel} · ${nextStop.name ?? nextStop.place}',
                    if (nextStop.appointment != null) 'Appt ${nextStop.appointment}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelMd.copyWith(color: muted),
                ),
              ],
              if (full) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (trip.truck != null) 'Truck ${trip.truck}',
                    if (trip.trailers != null) 'Trailer ${trip.trailers}',
                    if (trip.temperature != null) 'Temp ${trip.temperature}',
                    if (trip.loadedTrailer) 'Loaded trailer',
                  ].join(' · '),
                  style: AppText.labelMd.copyWith(color: muted),
                ),
                const Divider(height: AppSpacing.xl, color: Color(0xFFEEF2F7)),
                for (final s in trip.stops) _StopRow(stop: s, isNext: next?.stopId == s.id),
                if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(trip.notes!, style: AppText.bodySm.copyWith(color: muted)),
                ],
              ],
              if (suggestion != null) ...[
                const SizedBox(height: AppSpacing.md),
                _SuggestionBar(suggestion: suggestion, service: trips),
              ],
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              if (trip.status == 'on_hold')
                Text('On hold — dispatch will update you here', style: AppText.labelMd.copyWith(color: Colors.redAccent))
              else if ((trip.status == 'ended' || trip.status == 'paperwork') && widget.onOpenChat == null)
                Text('Delivered ✓ — send the BOL / POD photos here with 📎',
                    key: const Key('tripPaperworkHint'), style: AppText.labelMd.copyWith(color: CurrentTripCard._amber))
              else if (trip.status == 'ended' || trip.status == 'paperwork')
                _WideButton(
                  key: const Key('tripPaperworkButton'),
                  label: 'Send BOL / POD photos',
                  icon: Icons.photo_camera_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: widget.onOpenChat,
                )
              else if (next != null)
                _WideButton(
                  key: const Key('tripNextButton'),
                  label: next.label,
                  icon: CurrentTripCard._iconFor(next.action),
                  color: CurrentTripCard._green,
                  busy: trips.busy.value,
                  onTap: () => CurrentTripCard._confirmThen(context, next, () => trips.act(next.action, stopId: next.stopId)),
                ),
              if (full) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: TColors.navyHeaderDeep),
                      onPressed: () => CurrentTripCard._reportProblem(context, trips),
                      icon: const Icon(Icons.report_problem_rounded, size: 18),
                      label: const Text('Report problem'),
                    ),
                    const Spacer(),
                    if (canUndo)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: TColors.navyHeaderDeep),
                        onPressed: trips.undo,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Undo'),
                      ),
                  ],
                ),
              ],
              if (trips.pendingCount.value > 0)
                Text('${trips.pendingCount.value} update waiting for signal',
                    style: AppText.labelSm.copyWith(color: CurrentTripCard._amber)),
            ],
          ),
        ),
      );
    });
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.isNext});
  final TripStop stop;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final done = stop.departedAt != null || (stop.arrivedAt != null && stop.type == 'drop');
    final here = stop.arrivedAt != null && !done;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : here
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done
                ? CurrentTripCard._green
                : isNext || here
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${stop.typeLabel} · ${stop.name ?? stop.place}',
                    style: AppText.labelMd.copyWith(color: CurrentTripCard._ink, fontWeight: isNext ? FontWeight.w700 : FontWeight.w500)),
                Text(
                  [stop.place, if (stop.appointment != null) 'Appt ${stop.appointment}'].where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.labelSm.copyWith(color: CurrentTripCard._muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.suggestion, required this.service});
  final TripSuggestion suggestion;
  final TripService service;

  @override
  Widget build(BuildContext context) {
    final problem = suggestion.action == 'problem';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: TColors.navyHeaderDeep.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: TColors.navyHeaderDeep, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(problem ? suggestion.label : 'Update the trip: ${suggestion.label}?',
                style: AppText.labelMd.copyWith(color: CurrentTripCard._ink)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: CurrentTripCard._muted),
            onPressed: () => service.suggestion.value = null,
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TColors.navyHeaderDeep, foregroundColor: Colors.white),
            onPressed: () {
              if (problem) {
                service.suggestion.value = null;
                CurrentTripCard._reportProblem(context, service);
              } else {
                service.act(suggestion.action, stopId: suggestion.stopId);
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Text(text, style: AppText.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _WideButton extends StatelessWidget {
  const _WideButton({super.key, required this.label, required this.icon, required this.color, this.onTap, this.busy = false});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            textStyle: AppText.labelLg.copyWith(fontSize: 16),
          ),
          onPressed: busy ? null : onTap,
          icon: busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(icon),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      );
}
