import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';
import 'package:uscitylink/views/driver/views/driver_profile_view.dart';
import 'package:uscitylink/views/driver/views/fuel_stations/fuel_stations_view.dart';
import 'package:uscitylink/views/driver/views/training_view.dart';

class DriverCustomDrawer extends StatefulWidget {
  final GlobalKey<ScaffoldState> globalKey;

  DriverCustomDrawer({super.key, required this.globalKey});

  @override
  State<DriverCustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<DriverCustomDrawer>
    with WidgetsBindingObserver {
  final loginController = Get.put(LoginController());

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    loginController.getProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  void _close() => widget.globalKey.currentState?.closeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _item(
                      icon: Icons.badge_rounded,
                      color: TColors.navyHeaderDeep,
                      title: 'My Information',
                      onTap: () {
                        _close();
                        Get.to(() => DriverProfileView());
                      },
                    ),
                    _item(
                      icon: Icons.description_rounded,
                      color: const Color(0xFF2E5BFF),
                      title: 'Documents',
                      onTap: () {
                        _close();
                        Get.to(() => DocumentView());
                      },
                    ),
                    _item(
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF0E9A83),
                      title: 'Pay',
                      onTap: () {
                        _close();
                        Get.to(() => DriverPayView());
                      },
                    ),
                    _item(
                      icon: Icons.school_rounded,
                      color: TColors.brandGreen,
                      title: 'Training',
                      onTap: () {
                        _close();
                        Get.to(() => TrainingView());
                      },
                    ),
                    _item(
                      icon: Icons.ev_station_rounded,
                      color: TColors.brandGold,
                      title: 'Fuel Stations',
                      onTap: () {
                        _close();
                        Get.to(() => FuelStationsView());
                      },
                    ),
                    _item(
                      icon: Icons.password_rounded,
                      color: const Color(0xFF2E5BFF),
                      title: 'Change Password',
                      onTap: () {
                        _close();
                        Get.toNamed(AppRoutes.driverChangePassword);
                      },
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Divider(color: Colors.grey.shade200, height: 1),
                    ),
                    _item(
                      icon: Icons.logout_rounded,
                      color: TColors.brandRed,
                      title: 'Logout',
                      onTap: () {
                        _close();
                        loginController.logOut();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TColors.navyHeader, TColors.navyHeaderDeep],
        ),
      ),
      child: ClipRRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    InkWell(
                      onTap: _close,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final profile = loginController.userProfile.value;
                  final username = profile.username ?? '';
                  final email = profile.user?.email ?? '';
                  final profilePic = profile.profilePic;
                  return Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4), width: 1.5),
                        ),
                        child: (profilePic != null && profilePic.isNotEmpty)
                            ? Image.network(
                                profilePic,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    _getInitials(username),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _getInitials(username),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username.isNotEmpty ? username : 'Driver',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
