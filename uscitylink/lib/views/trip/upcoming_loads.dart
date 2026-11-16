import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/trip/respond_buttons.dart';

/// The loads lined up for the driver, in order: Upcoming, each answered with Accept / Reject. When the load
/// the driver is on is delivered, #1 takes over the main card by itself — already accepted if the driver
/// accepted it here ("Loaded — rolling" is next), otherwise with Accept / Reject. Nothing here when none.
class UpcomingLoads extends StatelessWidget {
  const UpcomingLoads({super.key, this.service});

  /// For tests; the app uses the registered TripService.
  final TripService? service;

  @override
  Widget build(BuildContext context) {
    final trips = service ?? (Get.isRegistered<TripService>() ? Get.find<TripService>() : null);
    if (trips == null) return const SizedBox.shrink();
    return Obx(() {
      final list = trips.upcoming.toList();
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        key: const Key('upcomingLoads'),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Upcoming', style: AppText.titleMd),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: Text('${list.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3730A3))),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < list.length; i++) _UpcomingCard(trip: list[i], index: i, service: trips),
        ]),
      );
    });
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.trip, required this.index, required this.service});
  final CurrentTrip trip;
  final int index;
  final TripService service;

  @override
  Widget build(BuildContext context) {
    final appt = trip.stops.map((s) => s.appointment == null ? null : '${s.typeLabel} ${s.appointment}').whereType<String>().firstOrNull;
    final gear = [if (trip.truck != null) 'Truck ${trip.truck}', if (trip.trailers != null) 'Trailer ${trip.trailers}', if (trip.temperature != null) 'Temp ${trip.temperature}'].join(' · ');
    return Container(
      key: Key('upcoming_${trip.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: trip.accepted ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 13, backgroundColor: const Color(0xFFE0E7FF), child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF3730A3)))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Load ${trip.loadNo ?? trip.tripNo}', style: AppText.labelLg.copyWith(fontSize: 15))),
          if (trip.accepted)
            Container(
              key: Key('upcomingAccepted_${trip.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(AppRadii.pill)),
              child: const Text('Accepted ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
            ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(trip.routeText, style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        if (appt != null) Text(appt, style: AppText.bodySm.copyWith(color: const Color(0xFF64748B))),
        if (gear.isNotEmpty) Text(gear, style: AppText.bodySm.copyWith(color: const Color(0xFF64748B))),
        const SizedBox(height: AppSpacing.md),
        if (trip.accepted)
          Row(children: [
            const Expanded(child: Text('You accepted it. It becomes your load when the current one is delivered.', style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)))),
            TextButton(key: Key('upcomingReject_${trip.id}'), style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)), onPressed: () => service.respond(trip, 'reject'), child: const Text('Reject')),
          ])
        else
          Obx(() => AcceptRejectRow(
                acceptKey: Key('upcomingAccept_${trip.id}'),
                rejectKey: Key('upcomingReject_${trip.id}'),
                busy: service.busy.value,
                onAccept: () => service.respond(trip, 'accept'),
                onReject: () => service.respond(trip, 'reject'),
              )),
      ]),
    );
  }
}
