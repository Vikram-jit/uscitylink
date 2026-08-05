// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/main.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/utils/utils.dart';

import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/daily_inspection/add_inspection_screen.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';
import 'package:uscitylink/views/driver/views/driver_profile_view.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/fuel_stations_view.dart';
import 'package:uscitylink/views/driver/views/training_view.dart';

const double _kKpiCardHeight = 112;
const double _kKpiOverlap = 46;
const double _kKpiOverflow = _kKpiCardHeight - _kKpiOverlap;
const double _kKpiRadius = 6;

/// Values the dashboard renders that `GET /user/dashboard` does not return yet.
///
/// They are collected here rather than scattered through the tree so that
/// swapping each one for a real `DashboardModel` field is a single-site edit.
/// TODO(api): replace each of these as the endpoint grows.
class _Placeholder {
  const _Placeholder._();

  static const int trucksInUse = 2;
  static const int trailersInUse = 1;
}

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver, RouteAware {
  SocketService socketService = Get.find<SocketService>();
  DashboardController _dashboardController = Get.put(DashboardController());
  ChannelController channelController = Get.find<ChannelController>();
  TruckController truckController = Get.put(TruckController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  NetworkService _networkService = Get.find<NetworkService>();
  HiveController _hiveController = Get.find<HiveController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getDashboard();
    if (socketService.isConnected.value) {
      if (_hiveController.isProcessing.value == false) {
        // socketService.socket.disconnect();
      }
    }
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        // if (_hiveController.isProcessing.value == false) {
        socketService.socket.disconnect();
        //}
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
          //socketService.sendQueueMessage();
        });
      }
      _dashboardController.getDashboard();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _dashboardController.getDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Current semi-monthly pay period (1st–15th, 16th–end of month), formatted
  /// the way the pay screen labels it. Derived from today's date rather than
  /// hardcoded, so it stays correct without an API field.
  String get _payPeriod {
    final now = DateTime.now();
    final isFirstHalf = now.day <= 15;
    final start = DateTime(now.year, now.month, isFirstHalf ? 1 : 16);
    final end = isFirstHalf
        ? DateTime(now.year, now.month, 15)
        : DateTime(now.year, now.month + 1, 0);
    final f = DateFormat('MMM d');
    return '${f.format(start)} – ${f.format(end)}, ${now.year}';
  }

  /// Whether anything has ever been loaded (from the network or the Hive
  /// cache). Drives the difference between a cold start — which gets a
  /// full-screen spinner — and a refresh, which must keep the existing content
  /// on screen so the pull gesture's own indicator survives the rebuild.
  bool get _hasDashboardData {
    final d = _dashboardController.dashboard.value;
    return d.messageCount != null || d.trucks != null || d.totalAmount != null;
  }

  Future<void> _refresh() async {
    _dashboardController.getDashboard();
    // getDashboard() is fire-and-forget; hold the spinner until the controller
    // flips `loading` back off so the gesture doesn't snap shut instantly.
    await _dashboardController.loading.stream
        .firstWhere((isLoading) => isLoading == false)
        .timeout(const Duration(seconds: 12), onTimeout: () => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: TColors.surfaceCanvas,
        body: Obx(() {
          if (_dashboardController.loading.value && !_hasDashboardData) {
            return SizedBox(
              height: TDeviceUtils.getScreenHeight(),
              child: const Center(
                child: CircularProgressIndicator(color: TColors.navyHeader),
              ),
            );
          }

          final dashboard = _dashboardController.dashboard.value;
          final messageCount = dashboard.messageCount ?? 0;
          // Nullable rather than defaulted to 0 — the dashboard API only
          // populates `trucks` reliably; `trailerCount` regularly comes back
          // empty, and showing "0" for that would read as "you have zero
          // trailers" instead of "this data isn't available."
          final trucks = dashboard.trucks ?? '';
          final trailers = dashboard.trailerCount;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: TColors.navyHeaderDeep,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          _Header(
                            greeting: _greeting,
                            connected: _networkService.connected,
                          ),
                          const SizedBox(height: _kKpiOverflow),
                        ],
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: 0,
                        child: SizedBox(
                          height: 90,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.forum_rounded,
                                  value: '$messageCount',
                                  label: 'Unread Messages',
                                  caption: '',
                                  gradient: AppGradients.messages,
                                  glowColor: TColors.violet,
                                  onTap: () => Get.to(() => ChatView()),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.account_balance_wallet_rounded,
                                  value: '\$${dashboard.totalAmount ?? 0}',
                                  label: 'Pay This Period',
                                  caption: "",
                                  gradient: AppGradients.pay,
                                  glowColor: TColors.teal,
                                  onTap: () => Get.to(() => DriverPayView()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOTE: condition intentionally left as it was found.
                        // It reads inverted against the "Inspection Required"
                        // copy, but flipping it on a guess would suppress the
                        // prompt for every driver if the API field actually
                        // means "an inspection is due". Verify server-side.
                        if (dashboard.isInspectionDone ?? false) ...[
                          _InspectionBanner(
                            onTap: () => Get.to(() => AddInspectionScreen()),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        _SectionHeader(
                          icon: Icons.local_shipping_rounded,
                          accent: TColors.brandGreen,
                          title: 'Fleet Overview',
                          subtitle: 'Your assigned vehicles',
                          actionLabel: 'View all',
                          onAction: () {
                            truckController.changeTab(0);
                            Get.to(() => DocumentView(tabIndexDefault: 0));
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FleetCard(
                          trucks: trucks,
                          trucksInUse: _Placeholder.trucksInUse,
                          trailers: trailers,
                          trailersInUse: _Placeholder.trailersInUse,
                          onTapTrucks: () {
                            truckController.changeTab(0);
                            Get.to(() => DocumentView(tabIndexDefault: 0));
                          },
                          onTapTrailers: () {
                            truckController.changeTab(1);
                            Get.to(() => DocumentView(tabIndexDefault: 1));
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionHeader(
                          icon: Icons.bolt_rounded,
                          accent: TColors.violet,
                          title: 'Quick Access',
                          subtitle: 'Everything you need, right here',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickAccessGrid(
                          items: [
                            _QuickAccessItem(
                              icon: Icons.ev_station_rounded,
                              accent: TColors.brandGreen,
                              title: 'Fuel Stations',
                              subtitle: 'Find nearby fuel stops',
                              onTap: () => Get.to(() => FuelStationsView()),
                            ),
                            _QuickAccessItem(
                              icon: Icons.badge_rounded,
                              accent: TColors.violet,
                              title: 'My Information',
                              subtitle: 'Profile & documents',
                              badge: (dashboard.isDocumentExpired ?? false)
                                  ? 'Expired'
                                  : null,
                              badgeColor: TColors.brandRed,
                              onTap: () => Get.to(() => DriverProfileView()),
                            ),
                            _QuickAccessItem(
                              icon: Icons.school_rounded,
                              accent: TColors.alertOrange,
                              title: 'Training',
                              subtitle: 'Required safety videos',
                              onTap: () => Get.to(() => TrainingView()),
                            ),
                            _QuickAccessItem(
                              icon: Icons.inventory_2_rounded,
                              accent: TColors.navyHeaderDeep,
                              title: 'Loads',
                              subtitle: 'View upcoming assignments',
                              badge: 'Soon',
                              badgeColor: TColors.textMuted,
                              onTap: () => Utils.snackBar(
                                'Coming soon',
                                'Load assignments will appear here once '
                                    'dispatch is connected.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _WeeklyStatsCard(
                          weeklyDrivingMinutes: dashboard.weeklyDrivingMinutes,
                          safetyScore: dashboard.safetyScore,
                        ),
                        SizedBox(
                          height: AppSpacing.xxl + kBottomNavigationBarHeight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String greeting;
  final RxBool connected;

  const _Header({required this.greeting, required this.connected});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.sm),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.header),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Full-bleed photo — the whole header shows the scene, with a
            // single flat overlay darkening it uniformly rather than a
            // directional scrim that hides part of the image behind solid
            // navy.
            Positioned.fill(
              child: Image.asset(
                TImages.truckNew,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.35),
              ),
            ),
            // Flat black overlay across the whole photo — uniform contrast
            // boost so text stays legible over any part of the image.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.70)),
              ),
            ),
            // Thin top/bottom fade so the status bar icons and the curved
            // lower edge both stay legible against whatever the photo is
            // doing at that particular edge.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                        TColors.navyHeaderDeep.withValues(alpha: 0.35),
                      ],
                      stops: const [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                topInset + AppSpacing.base,
                AppSpacing.lg,
                AppSpacing.xxl + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Image.asset(TImages.logo, fit: BoxFit.contain),
                      ),
                      const Spacer(),
                      Obx(() =>
                          connected.value ? const SizedBox() : _syncingPill()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    '$greeting, Driver 👋',
                    style: AppText.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ready for\nthe road today?',
                    style: AppText.displayLg.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Obx(() => _StatusPill(connected: connected.value)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 1.8,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Syncing',
            style: AppText.labelSm.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// Persistent connection state. Previously the network state only surfaced as a
/// pill that appeared on failure, which gave the driver no positive signal that
/// the app was actually live.
class _StatusPill extends StatelessWidget {
  final bool connected;

  const _StatusPill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final Color dot = connected ? const Color(0xFF34D399) : TColors.brandGold;
    final String label =
        connected ? 'All systems operational' : 'Reconnecting…';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppText.labelMd.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI cards
// ---------------------------------------------------------------------------

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String caption;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.caption,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Top row: icon + value + chevron. Bottom: label and caption on their own
    // full-width rows, rather than squeezed into a middle column next to the
    // icon — that's what was overflowing, since the parent row stretches this
    // card to a fixed height regardless of how much the three stacked lines
    // actually needed.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_kKpiRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kKpiRadius),
          gradient: gradient,
          boxShadow: AppShadows.glow(glowColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: gradient.colors.last, size: 18),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.numeric(AppText.titleMd)
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm.copyWith(color: Colors.white),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                //const SizedBox(height: 2),

                // Text(
                //   caption,
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                //   style: AppText.labelSm.copyWith(
                //     color: Colors.white.withValues(alpha: 0.78),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.titleLg.copyWith(color: TColors.textStrong),
              ),
              Text(
                subtitle,
                style: AppText.bodySm.copyWith(color: TColors.textMuted),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style:
                        AppText.labelLg.copyWith(color: TColors.navyHeaderDeep),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: TColors.navyHeaderDeep,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inspection banner
// ---------------------------------------------------------------------------

class _InspectionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _InspectionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        decoration: BoxDecoration(
          color: TColors.alertInk,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          boxShadow: AppShadows.raised,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: TColors.alertOrange),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppGradients.alertIcon,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Daily Inspection Required',
                              style:
                                  AppText.labelLg.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please complete your vehicle inspection for '
                              'today.',
                              style: AppText.labelMd.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //const SizedBox(width: AppSpacing.md),
                      _StartNowButton(onTap: onTap),
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
}

class _StartNowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartNowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TColors.alertOrange,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(
              //   'Start Now',
              //   style: AppText.labelLg.copyWith(color: Colors.white),
              // ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fleet card
// ---------------------------------------------------------------------------

class _FleetCard extends StatelessWidget {
  final String? trucks;
  final int trucksInUse;
  final int? trailers;
  final int trailersInUse;
  final VoidCallback onTapTrucks;
  final VoidCallback onTapTrailers;

  const _FleetCard({
    required this.trucks,
    required this.trucksInUse,
    required this.trailers,
    required this.trailersInUse,
    required this.onTapTrucks,
    required this.onTapTrailers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _half(
                icon: Icons.local_shipping_rounded,
                accent: TColors.brandGreen,
                total: trucks,
                inUse: trucksInUse,
                label: 'Trucks',
                onTap: onTapTrucks,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: TColors.hairline,
              indent: AppSpacing.base,
              endIndent: AppSpacing.base,
            ),
            Expanded(
              child: _half(
                icon: Icons.rv_hookup_rounded,
                accent: TColors.navyHeaderDeep,
                total: "Trailers",
                inUse: trailersInUse,
                label: 'Trailers',
                onTap: onTapTrailers,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _half({
    required IconData icon,
    required Color accent,
    required String? total,
    required int inUse,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total == null ? '—' : '$total',
                        maxLines: 1,
                        style: AppText.numeric(AppText.displaySm).copyWith(
                          color: total == null
                              ? TColors.textMuted
                              : TColors.textStrong,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.bodySm.copyWith(color: TColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // ClipRRect(
            //   borderRadius: BorderRadius.circular(AppRadii.pill),
            //   child: LinearProgressIndicator(
            //     value: fraction,
            //     minHeight: 4,
            //     backgroundColor: TColors.hairline,
            //     valueColor: AlwaysStoppedAnimation<Color>(accent),
            //   ),
            // ),
            // const SizedBox(height: AppSpacing.sm),
            // Text(
            //   '$used in use  ·  $available available',
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: AppText.numeric(AppText.labelMd)
            //       .copyWith(color: TColors.textMuted),
            // ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick access
// ---------------------------------------------------------------------------

class _QuickAccessItem {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });
}

/// A single horizontally scrolling row rather than a grid, so adding a fifth
/// or sixth quick-access item later never forces a re-tuned column count —
/// it just scrolls.
///
/// Every card is the same fixed width/height, and every row inside it —
/// icon, title, subtitle, status — is its own fixed-height slot rather than
/// letting the Column size to its content. That's what makes the cards line
/// up identically whether or not a given item has a status badge, and it's
/// what keeps a long label from ever pushing the card taller than its
/// neighbours: text is capped at one line with an ellipsis instead of
/// wrapping onto a second line, which is what was reading as unpolished.
class _QuickAccessGrid extends StatelessWidget {
  final List<_QuickAccessItem> items;

  const _QuickAccessGrid({required this.items});
  static const double _tileWidth = 125;
  static const double _tileHeight = 190;

  static const double _iconSlot = 40;
  static const double _titleSlot = 20;
  static const double _subtitleSlot = 30;
  static const double _statusSlot = 22;
  static const double _arrowSlot = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tileHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => SizedBox(
          width: _tileWidth,
          child: _tile(items[index]),
        ),
      ),
    );
  }

  Widget _tile(_QuickAccessItem item) {
    final badgeColor = item.badgeColor ?? TColors.textMuted;
    return Material(
      color: TColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Ink(
          decoration: BoxDecoration(
            color: TColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          // `stretch` so each slot spans the tile's full width — Center/Align
          // inside a slot only has room to work with if the slot isn't
          // already shrink-wrapped to its child.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _iconSlot,
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.accent, size: 17),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _titleSlot,
                child: Center(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(
                      color: TColors.textStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: _subtitleSlot,
                child: Center(
                  child: Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    // maxLines: 1,
                    // overflow: TextOverflow.ellipsis,
                    style: AppText.labelSm.copyWith(color: TColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _statusSlot,
                child: Center(
                  child: item.badge == null
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            item.badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.labelSm.copyWith(color: badgeColor),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: _arrowSlot,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: item.accent,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly stats
// ---------------------------------------------------------------------------

class _WeeklyStatsCard extends StatelessWidget {
  final int? weeklyDrivingMinutes;
  final int? safetyScore;

  const _WeeklyStatsCard({
    required this.weeklyDrivingMinutes,
    required this.safetyScore,
  });

  static const int _hosLimitHours = 60;

  /// Coarse label buckets for a 0-100 Samsara safety score. Thresholds match
  /// Samsara's own driver-scorecard bands.
  String _scoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs work';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = weeklyDrivingMinutes;
    final hours = minutes == null ? null : minutes ~/ 60;
    final mins = minutes == null ? null : minutes % 60;
    final fraction = minutes == null
        ? 0.0
        : (minutes / (_hosLimitHours * 60)).clamp(0.0, 1.0);
    final score = safetyScore;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: AppText.labelSm.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statLabel(Icons.schedule_rounded, 'Driving Time'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        hours == null ? '—' : '${hours}h ${mins}m',
                        style: AppText.numeric(AppText.displaySm)
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'of $_hosLimitHours' 'h limit',
                        style: AppText.numeric(AppText.labelMd).copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                  ),
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statLabel(Icons.verified_user_rounded, 'Safety Score'),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            score == null ? '—' : '$score',
                            style: AppText.numeric(AppText.displaySm)
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            score == null ? 'No data' : _scoreLabel(score),
                            style: AppText.labelMd.copyWith(
                              color: score == null
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.62)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

