import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/services/trip/trip_models.dart';
import 'package:uscitylink/services/trip/trip_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/trip/current_trip_card.dart';

/// Driver bottom-nav "Loads": the load they're on (same one-button card as the dashboard) and every
/// load dispatch sent them before, newest first. Tap a load for its stops and times.
class LoadsView extends StatefulWidget {
  const LoadsView({super.key, this.service, this.standalone = false});

  /// Opened on its own (from the chat header) rather than as the bottom-nav tab: shows a back arrow
  final bool standalone;

  /// For tests; the app uses the registered TripService.
  final TripService? service;

  @override
  State<LoadsView> createState() => _LoadsViewState();
}

/// The Loads tab of the driver's bottom bar (Home · Loads · Messages · Settings).
void openLoadsTab() {
  if (Get.isRegistered<ChannelController>()) Get.find<ChannelController>().currentIndex.value = 1;
  if (Get.isRegistered<LoginController>()) Get.find<LoginController>().setTabIndex(1);
}

/// Dashboard: a way to the Loads screen when there's no current load (the trip card has its own).
class MyLoadsShortcut extends StatelessWidget {
  const MyLoadsShortcut({super.key, this.service});
  final TripService? service;

  @override
  Widget build(BuildContext context) {
    final trips = service ?? TripService.to;
    return Obx(() {
      if (trips.current.value != null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            key: const Key('myLoadsShortcut'),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: openLoadsTab,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: TColors.navyHeaderDeep.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping_rounded, color: TColors.navyHeaderDeep, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My loads', style: AppText.labelLg),
                        Text('No load right now · see your past loads', style: AppText.labelSm.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// The dispatch chat (where BOL / POD photos go), as the dashboard opens it.
void openDispatchChat() {
  final channel = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>().dashboard.value.channel : null;
  if (channel?.id == null) {
    Get.to(() => ChatView());
    return;
  }
  if (Get.isRegistered<SocketService>()) Get.find<SocketService>().updateActiveChannel(channel!.id!);
  Get.toNamed(AppRoutes.driverMessage, arguments: {'channelId': channel!.id, 'name': channel.name});
}

class _LoadsViewState extends State<LoadsView> {
  TripService get trips => widget.service ?? TripService.to;

  @override
  void initState() {
    super.initState();
    if (widget.service == null) {
      trips.refresh();
      trips.loadHistory(reset: true);
    }
  }

  Future<void> _reload() async {
    await Future.wait([trips.refresh(), trips.loadHistory(reset: true)]);
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteStatusBar(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            _LoadsHeader(
                title: 'My loads',
            onBack: widget.standalone ? () => Get.back() : null,
                subtitle: 'Loads from dispatch',
                trailing: IconButton(
                  onPressed: _reload,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                )),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: Obx(() {
                  final current = trips.current.value;
                  final past = trips.history.where((t) => t.id != current?.id).toList();
                  return ListView(
                    key: const Key('loadsList'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      const _SectionTitle('Current load'),
                      if (current != null)
                        CurrentTripCard(service: widget.service, onOpenChat: openDispatchChat)
                      else
                        const _Empty(
                          icon: Icons.local_shipping_outlined,
                          text: 'No load right now — dispatch will send your next load to your chat and it shows up here.',
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      const _SectionTitle('History'),
                      if (past.isEmpty && !trips.historyLoading.value)
                        const _Empty(icon: Icons.history_rounded, text: 'Your delivered loads will be listed here.'),
                      for (final t in past) _LoadTile(trip: t),
                      if (trips.historyLoading.value)
                        const Padding(padding: EdgeInsets.all(AppSpacing.base), child: Center(child: CircularProgressIndicator()))
                      else if (trips.hasMoreHistory)
                        Center(
                          child: TextButton(
                            key: const Key('loadsMore'),
                            onPressed: () => trips.loadHistory(),
                            child: const Text('Load more'),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same top bar as the Messages screen: navy gradient, rounded bottom, white title and icons.
class _LoadsHeader extends StatelessWidget {
  const _LoadsHeader({required this.title, this.subtitle, this.onBack, this.trailing});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 12, topInset + 12, 12, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TColors.navyHeader, TColors.navyHeaderDeep],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
              ),
            ),
            Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      ),
                      if (subtitle != null) Text(subtitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5)),
                    ],
                  ),
                ),
                if (trailing != null) trailing! else const SizedBox(width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// White status bar icons over the navy header (as the Messages screen does).
class _WhiteStatusBar extends StatelessWidget {
  const _WhiteStatusBar({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: child,
      );
}

/// "Nov 6"
String shortDate(DateTime? d) {
  if (d == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}';
}

/// "Nov 6, 2:55 PM"
String dateTime(DateTime? d) {
  if (d == null) return '—';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${shortDate(d)}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

Color statusColor(String status) => tripStatusColor(status);

class _LoadTile extends StatelessWidget {
  const _LoadTile({required this.trip});
  final CurrentTrip trip;

  @override
  Widget build(BuildContext context) {
    final first = trip.firstStop;
    final last = trip.lastStop;
    final when = trip.completedAt ?? trip.endedAt ?? trip.sentAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          key: Key('load_${trip.id}'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => Get.to(() => LoadDetailView(trip: trip)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: statusColor(trip.status).withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.local_shipping_rounded, color: statusColor(trip.status), size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Trip #${trip.tripNo}', style: AppText.labelLg),
                          const Spacer(),
                          Text(trip.statusLabel,
                              style: AppText.labelSm.copyWith(color: statusColor(trip.status), fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${first?.place ?? '—'} → ${last?.place ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMd,
                      ),
                      Text(
                        [
                          '${trip.stops.length} stop${trip.stops.length == 1 ? '' : 's'}',
                          if (trip.truck != null) 'Truck ${trip.truck}',
                          if (when != null) shortDate(when),
                        ].join(' · '),
                        style: AppText.labelSm.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One load: when it was sent / started / delivered / completed, and every stop with its times.
class LoadDetailView extends StatelessWidget {
  const LoadDetailView({super.key, required this.trip});
  final CurrentTrip trip;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (trip.truck != null) 'Truck ${trip.truck}',
      if (trip.trailers != null) 'Trailer ${trip.trailers}',
      if (trip.temperature != null) 'Temp ${trip.temperature}',
      if (trip.loadedTrailer) 'Loaded trailer',
    ].join(' · ');
    return _WhiteStatusBar(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            _LoadsHeader(
              title: 'Trip #${trip.tripNo}',
              subtitle: trip.statusLabel,
              onBack: () => Get.back(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Card(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(details.isEmpty ? 'Load' : details, style: AppText.bodyMd)),
                          Text(trip.statusLabel,
                              style: AppText.labelMd.copyWith(color: statusColor(trip.status), fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      _Line('Sent', dateTime(trip.sentAt)),
                      _Line('Started', dateTime(trip.startedAt)),
                      _Line('Delivered', dateTime(trip.endedAt)),
                      _Line('Completed', dateTime(trip.completedAt)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _SectionTitle('Stops'),
                  for (final s in trip.stops)
                    _Card(
                      children: [
                        Text('${s.typeLabel} · ${s.name ?? s.place}', style: AppText.labelLg),
                        const SizedBox(height: 2),
                        Text(
                          [
                            s.street,
                            [s.city, s.state, s.zip].where((x) => x != null && x.isNotEmpty).join(' ')
                          ].where((x) => x != null && x.isNotEmpty).join(', '),
                          style: AppText.bodySm.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (s.appointment != null) _Line('Appointment', s.appointment!),
                        if (s.arrivedAt != null) _Line('Arrived', dateTime(s.arrivedAt)),
                        if (s.departedAt != null) _Line('Left', dateTime(s.departedAt)),
                      ],
                    ),
                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const _SectionTitle('Notes'),
                    _Card(children: [Text(trip.notes!, style: AppText.bodyMd)]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: AppText.labelMd.copyWith(color: Colors.grey.shade600))),
            Expanded(child: Text(value, style: AppText.labelMd)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
        child: Text(text, style: AppText.titleMd),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => _Card(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade400),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(text, style: AppText.bodyMd.copyWith(color: Colors.grey.shade600))),
            ],
          ),
        ],
      );
}
