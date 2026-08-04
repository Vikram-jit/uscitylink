import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/controller/security_dashboard_controller.dart';
import 'package:uscitylink/controller/vehicle_entry_form_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'vehicle_entry_form_view.dart';
import 'vehicle_entry_list_view.dart';
import 'vehicle_inspection_vehicles_view.dart';

const double _kKpiCardHeight = 132;
const double _kKpiOverlap = 40;
const double _kKpiOverflow = _kKpiCardHeight - _kKpiOverlap;
const double _kTabletMaxWidth = 760;

class SecurityDashboardView extends StatefulWidget {
  const SecurityDashboardView({super.key});

  @override
  State<SecurityDashboardView> createState() => _SecurityDashboardViewState();
}

class _SecurityDashboardViewState extends State<SecurityDashboardView> {
  final SecurityDashboardController _controller =
      Get.put(SecurityDashboardController());
  final LoginController _loginController = Get.put(LoginController());

  @override
  void initState() {
    super.initState();
    _controller.getDashboard();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Obx(() {
          final dashboard = _controller.dashboard.value;
          final firstLoad = _controller.loading.value && dashboard.date == null;

          if (firstLoad) {
            return const Center(
                child: CircularProgressIndicator(color: TColors.navyHeader));
          }

          return RefreshIndicator(
            color: TColors.navyHeader,
            onRefresh: () async => _controller.getDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
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
                            isTablet: isTablet,
                            onLogout: _loginController.logOut,
                          ),
                          const SizedBox(height: _kKpiOverflow),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _ResponsiveContainer(
                          isTablet: isTablet,
                          child: SizedBox(
                            height: _kKpiCardHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _KpiCard(
                                    icon: Icons.login_rounded,
                                    label: 'Total Entries',
                                    value: '${dashboard.totalEntries ?? 0}',
                                    gradient: const [
                                      Color(0xFF16A34A),
                                      Color(0xFF22C55E),
                                    ],
                                    onTap: () => Get.to(() => const VehicleEntryFormView(
                                        status: VehicleEntryStatus.entry)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _KpiCard(
                                    icon: Icons.logout_rounded,
                                    label: 'Total Departures',
                                    value: '${dashboard.totalDepartures ?? 0}',
                                    gradient: const [
                                      Color(0xFFDC2626),
                                      Color(0xFFEF4444),
                                    ],
                                    onTap: () => Get.to(() => const VehicleEntryFormView(
                                        status: VehicleEntryStatus.depart)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _kKpiOverflow - 40),
                  _ResponsiveContainer(
                    isTablet: isTablet,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel(
                          title: 'Quick Access',
                          subtitle: 'Gate activity tools',
                        ),
                        const SizedBox(height: 10),
                        _QuickAccessGroup(
                          isTablet: isTablet,
                          items: [
                            _QuickAccessItem(
                              icon: Icons.assignment_turned_in_rounded,
                              iconColor: const Color(0xFF16A34A),
                              title: 'Vehicle Entry Log',
                              subtitle: 'View past truck & trailer entries',
                              onTap: () => Get.to(() => const VehicleEntryListView(
                                  status: VehicleEntryStatus.entry)),
                            ),
                            _QuickAccessItem(
                              icon: Icons.assignment_late_rounded,
                              iconColor: const Color(0xFFDC2626),
                              title: 'Vehicle Depart Log',
                              subtitle: 'View past truck & trailer departures',
                              onTap: () => Get.to(() => const VehicleEntryListView(
                                  status: VehicleEntryStatus.depart)),
                            ),
                            _QuickAccessItem(
                              icon: Icons.fact_check_rounded,
                              iconColor: const Color(0xFF1B3B8C),
                              title: 'Vehicle Inspections',
                              subtitle: 'Truck & trailer inspection checklists',
                              onTap: () =>
                                  Get.to(() => const VehicleInspectionVehiclesView()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
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

/// Centers content within a max width on tablet, full-width on phone —
/// the single responsive rule this whole screen is built around.
class _ResponsiveContainer extends StatelessWidget {
  final bool isTablet;
  final Widget child;

  const _ResponsiveContainer({required this.isTablet, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: isTablet ? _kTabletMaxWidth : double.infinity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final bool isTablet;
  final VoidCallback onLogout;

  const _Header({
    required this.greeting,
    required this.isTablet,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            0, topInset + (isTablet ? 20 : 16), 0, isTablet ? 66 : 60),
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
            Positioned(top: -50, right: -30, child: _orb(150, 0.06)),
            Positioned(bottom: -40, left: -50, child: _orb(160, 0.05)),
            _ResponsiveContainer(
              isTablet: isTablet,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: isTablet ? 14 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Security Gate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SECURITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
                    tooltip: 'Log Out',
                  ),
                ],
              ),
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
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
                color: gradient.last.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
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
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _QuickAccessItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  _QuickAccessItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });
}

class _QuickAccessGroup extends StatelessWidget {
  final bool isTablet;
  final List<_QuickAccessItem> items;

  const _QuickAccessGroup({required this.isTablet, required this.items});

  void _showComingSoon(_QuickAccessItem item) {
    Get.snackbar(
      item.title,
      'This feature is coming in a future update.',
      backgroundColor: TColors.navyHeader,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i != 0) const SizedBox(width: 14),
            Expanded(child: _card(items[i])),
          ],
        ],
      );
    }

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
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _row(items[i]),
            if (i != items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(
                    height: 1, color: Colors.grey.shade100, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _card(_QuickAccessItem item) {
    return InkWell(
      onTap: item.onTap ?? () => _showComingSoon(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                if (item.badge != null) _badge(item.badge!),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_QuickAccessItem item) {
    return InkWell(
      onTap: item.onTap ?? () => _showComingSoon(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (item.badge != null) ...[
              _badge(item.badge!),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
