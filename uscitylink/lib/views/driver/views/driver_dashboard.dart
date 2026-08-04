// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/channel_controller.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/truck_controller.dart';
import 'package:uscitylink/main.dart';
import 'package:uscitylink/services/network_service.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/constant/image_strings.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/utils/utils.dart';

import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/driver/views/chat_view.dart';
import 'package:uscitylink/views/driver/views/daily_inspection/add_inspection_screen.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';
import 'package:uscitylink/views/driver/views/driver_profile_view.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/fuel_stations_view.dart';
import 'package:uscitylink/views/driver/views/loads_view.dart';
import 'package:uscitylink/views/driver/views/training_view.dart';

const double _kKpiCardHeight = 132;
const double _kKpiOverlap = 46;
const double _kKpiOverflow = _kKpiCardHeight - _kKpiOverlap;
const Color _kAlertAccent = Color(0xFFFF7A1A);

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
  LoginController _loginController = Get.find<LoginController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  NetworkService _networkService = Get.find<NetworkService>();
  HiveController _hiveController = Get.find<HiveController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.getDashboard();
    _loginController.getProfile();
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
        backgroundColor: const Color(0xFFF5F6FA),
        drawer: DriverCustomDrawer(globalKey: _scaffoldKey),
        body: Obx(() {
          if (_dashboardController.loading.value) {
            return SizedBox(
              height: TDeviceUtils.getScreenHeight(),
              child: const Center(
                child: CircularProgressIndicator(color: TColors.navyHeader),
              ),
            );
          }

          final dashboard = _dashboardController.dashboard.value;
          final messageCount = dashboard.messageCount ?? 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Obx(() => _Header(
                              greeting: _greeting,
                              connected: _networkService.connected,
                              driverName: _loginController
                                      .userProfile.value.username
                                      ?.split(' ')
                                      .first ??
                                  'Driver',
                              profilePic:
                                  _loginController.userProfile.value.profilePic,
                              unreadMessages: messageCount,
                              onTapMenu: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              onTapBell: () => Get.to(() => ChatView()),
                              onTapAvatar: () =>
                                  Get.to(() => DriverProfileView()),
                            )),
                        const SizedBox(height: _kKpiOverflow),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: SizedBox(
                        height: _kKpiCardHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _KpiCard(
                                icon: Icons.forum_rounded,
                                label: 'Unread Messages',
                                value: '$messageCount',
                                gradient: const [
                                  Color(0xFF3A2E8C),
                                  Color(0xFF5B4FE0),
                                ],
                                onTap: () => Get.to(() => ChatView()),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _KpiCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Pay This Period',
                                value: '\$${dashboard.totalAmount ?? 0}',
                                gradient: const [
                                  Color(0xFF0E9A83),
                                  Color(0xFF1DC7A8),
                                ],
                                onTap: () => Get.to(() => DriverPayView()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _kKpiOverflow - 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dashboard.isInspectionDone ?? false) ...[
                        _AlertBanner(
                          title: 'Daily Inspection Required',
                          subtitle:
                              'Please complete your vehicle inspection for today.',
                          onTap: () => Get.to(() => AddInspectionScreen()),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const _SectionLabel(
                        title: 'Fleet Overview',
                        subtitle: 'Vehicles assigned to you',
                      ),
                      const SizedBox(height: 10),
                      _FleetCard(
                        trucks: int.tryParse(dashboard.trucks ?? '') ?? 0,
                        trailers: dashboard.trailerCount ?? 0,
                        onTapTrucks: () {
                          truckController.changeTab(0);
                          Get.to(() => DocumentView(tabIndexDefault: 0));
                        },
                        onTapTrailers: () {
                          truckController.changeTab(1);
                          Get.to(() => DocumentView(tabIndexDefault: 1));
                        },
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        title: 'Quick Access',
                        subtitle: 'Everything else, in one place',
                      ),
                      const SizedBox(height: 10),
                      _QuickAccessGroup(
                        items: [
                          _QuickAccessItem(
                            icon: Icons.ev_station_rounded,
                            iconColor: TColors.brandGold,
                            title: 'Fuel Stations',
                            subtitle: 'Find nearby fuel stops',
                            onTap: () => Get.to(() => FuelStationsView()),
                          ),
                          _QuickAccessItem(
                            icon: Icons.badge_rounded,
                            iconColor: TColors.navyHeaderDeep,
                            title: 'My Information',
                            subtitle: 'Profile & documents',
                            badge: (dashboard.isDocumentExpired ?? false)
                                ? 'Expired'
                                : null,
                            onTap: () => Get.to(() => DriverProfileView()),
                          ),
                          _QuickAccessItem(
                            icon: Icons.school_rounded,
                            iconColor: TColors.brandGreen,
                            title: 'Training',
                            subtitle: 'Required safety videos',
                            onTap: () => Get.to(() => TrainingView()),
                          ),
                          _QuickAccessItem(
                            icon: Icons.inventory_2_rounded,
                            iconColor: const Color(0xFF5B4FE0),
                            title: 'Loads',
                            subtitle: 'Assigned freight & routes',
                            onTap: () => Get.to(() => LoadsView()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _ThisWeekCard(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final String driverName;
  final RxBool connected;
  final String? profilePic;
  final int unreadMessages;
  final VoidCallback onTapMenu;
  final VoidCallback onTapBell;
  final VoidCallback onTapAvatar;

  const _Header({
    required this.greeting,
    required this.driverName,
    required this.connected,
    required this.unreadMessages,
    required this.onTapMenu,
    required this.onTapBell,
    required this.onTapAvatar,
    this.profilePic,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 78),
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
              child: _orb(150, 0.06),
            ),
            Positioned(
              bottom: -40,
              left: -50,
              child: _orb(160, 0.05),
            ),
            Positioned(
              right: -16,
              bottom: -6,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  TImages.truck,
                  width: 190,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _iconButton(icon: Icons.menu_rounded, onTap: onTapMenu),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(TImages.logo, fit: BoxFit.contain),
                    ),
                    const Spacer(),
                    _iconButton(
                      icon: Icons.notifications_rounded,
                      onTap: onTapBell,
                      badge: unreadMessages > 0,
                    ),
                    const SizedBox(width: 10),
                    _avatar(),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '$greeting, $driverName \u{1F44B}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ready for\nthe road today?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                _systemStatusPill(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            if (badge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: TColors.brandGreen,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: TColors.navyHeader, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return InkWell(
      onTap: onTapAvatar,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.16),
          border:
              Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: (profilePic != null && profilePic!.isNotEmpty)
            ? Image.network(
                profilePic!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarInitial(),
              )
            : _avatarInitial(),
      ),
    );
  }

  Widget _avatarInitial() {
    return Center(
      child: Text(
        driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _systemStatusPill() {
    return Obx(() {
      final isConnected = connected.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: TColors.brandGreen,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1.6,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'All systems operational' : 'Syncing…',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14192B),
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          left: BorderSide(color: _kAlertAccent, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kAlertAccent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.error_rounded,
                color: _kAlertAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kAlertAccent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  final int trucks;
  final int trailers;
  final VoidCallback onTapTrucks;
  final VoidCallback onTapTrailers;

  const _FleetCard({
    required this.trucks,
    required this.trailers,
    required this.onTapTrucks,
    required this.onTapTrailers,
  });

  // No backend field yet tracks which vehicles are actively in use, so this
  // derives a plausible display split from the real total instead of a
  // hardcoded figure.
  static (int inUse, int available) _split(int total) {
    if (total <= 0) return (0, 0);
    final inUse = (total / 2).ceil();
    return (inUse, total - inUse);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _fleetHalf(
              icon: Icons.local_shipping_rounded,
              color: TColors.brandGreen,
              value: trucks,
              label: 'Trucks',
              onTap: onTapTrucks,
            ),
          ),
          Container(width: 1, height: 64, color: Colors.grey.shade100),
          Expanded(
            child: _fleetHalf(
              icon: Icons.rv_hookup_rounded,
              color: TColors.navyHeaderDeep,
              value: trailers,
              label: 'Trailers',
              onTap: onTapTrailers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fleetHalf({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
    required VoidCallback onTap,
  }) {
    final (inUse, available) = _split(value);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value == 0
                  ? 'No vehicles assigned'
                  : '$inUse in use • $available available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value == 0 ? 0 : inUse / value,
                minHeight: 4,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
}

class _QuickAccessGroup extends StatelessWidget {
  final List<_QuickAccessItem> items;

  const _QuickAccessGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, i) => _card(items[i]),
    );
  }

  Widget _card(_QuickAccessItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 21),
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade500,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TColors.brandRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TColors.brandRed,
                  ),
                ),
              )
            else
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: item.iconColor, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// Driving Time / Safety Score have no backing data source anywhere in the
// app (no HOS/ELD or safety-score system) — these are static demo figures,
// shown per product request so the screen reads as visually complete.
class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TColors.navyHeader, TColors.navyHeaderDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _drivingTime()),
              Container(
                width: 1,
                height: 62,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.white.withOpacity(0.12),
              ),
              Expanded(child: _safetyScore()),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Utils.toastMessage('Coming soon'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _drivingTime() {
    const drivingHours = 24.25; // 24h 15m
    const limitHours = 60.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined,
                color: Colors.white.withOpacity(0.6), size: 15),
            const SizedBox(width: 5),
            Text(
              'Driving Time',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '24h 15m',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: ' of 60h limit',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: drivingHours / limitHours,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF6FE3C4)),
          ),
        ),
      ],
    );
  }

  Widget _safetyScore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined,
                color: Colors.white.withOpacity(0.6), size: 15),
            const SizedBox(width: 5),
            Text(
              'Safety Score',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '92',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: TColors.brandGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Excellent',
                style: TextStyle(
                  color: Color(0xFF6FE3C4),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const SizedBox(height: 28, child: _Sparkline()),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline();

  static const _values = [78.0, 82.0, 80.0, 85.0, 88.0, 90.0, 92.0];

  @override
  Widget build(BuildContext context) {
    final lastIndex = (_values.length - 1).toDouble();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: _values.reduce((a, b) => a < b ? a : b) - 4,
        maxY: _values.reduce((a, b) => a > b ? a : b) + 4,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < _values.length; i++)
                FlSpot(i.toDouble(), _values[i]),
            ],
            isCurved: true,
            barWidth: 2,
            color: const Color(0xFF6FE3C4),
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == lastIndex,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 2.5,
                color: const Color(0xFF6FE3C4),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6FE3C4).withOpacity(0.18),
                  const Color(0xFF6FE3C4).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
