import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class SecurityWelcomeView extends StatelessWidget {
  const SecurityWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final loginController = Get.put(LoginController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            _Header(isTablet: isTablet),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isTablet ? 480 : double.infinity),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 0 : 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isTablet ? 96 : 76,
                          height: isTablet ? 96 : 76,
                          decoration: BoxDecoration(
                            color: TColors.navyHeader.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            color: TColors.navyHeader,
                            size: isTablet ? 48 : 38,
                          ),
                        ),
                        SizedBox(height: isTablet ? 28 : 20),
                        Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: isTablet ? 30 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: TColors.navyHeader.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SECURITY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: TColors.navyHeader,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        Text(
                          'More features for your role are on the way.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 13.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: isTablet ? 40 : 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: loginController.logOut,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Log Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColors.navyHeader,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 18 : 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isTablet;

  const _Header({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            20, topInset + (isTablet ? 24 : 16), 20, isTablet ? 28 : 20),
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
            Positioned(top: -50, right: -30, child: _orb(140, 0.06)),
            Text(
              'Security Portal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
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
