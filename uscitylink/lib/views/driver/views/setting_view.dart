import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/model/user_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/widegts/document_status_card.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

import '../../../model/login_model.dart';

const double _kProfileCardOverflow = 150;

class SettingView extends StatefulWidget {
  SettingView({
    Key? key,
  }) : super(key: key);

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> with WidgetsBindingObserver {
  final loginController = Get.put(LoginController());
  SocketService socketService = Get.find<SocketService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    loginController.getProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
        Timer(Duration(seconds: 2), () {
          socketService.checkVersion();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        body: Obx(() {
          final profile = loginController.userProfile.value;
          final user = profile.user ?? UserModel();
          final documents = profile.documents ?? [];

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
                        _TopHeader(
                          onChangePassword: () =>
                              Get.toNamed(AppRoutes.driverChangePassword),
                          onLogout: loginController.logOut,
                        ),
                        const SizedBox(height: _kProfileCardOverflow),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: _ProfileCard(profile: profile, user: user),
                    ),
                  ],
                ),
                const SizedBox(height: _kProfileCardOverflow - 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatsSplitCard(
                        daysActive: _getDaysSince(profile.createdAt),
                        platform: profile.platform?.toUpperCase() ?? 'N/A',
                        version: profile.version ?? 'N/A',
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        title: 'Driver Information',
                        subtitle: 'Your contact & assignment details',
                      ),
                      const SizedBox(height: 10),
                      _InfoGroup(
                        rows: [
                          _InfoRowData(
                            icon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: user.phoneNumber ?? 'N/A',
                          ),
                          _InfoRowData(
                            icon: Icons.email_rounded,
                            label: 'Email Address',
                            value: user.email ?? 'N/A',
                          ),
                          _InfoRowData(
                            icon: Icons.location_city_rounded,
                            label: 'Yard ID',
                            value: user.yardId?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        title: 'Account Details',
                        subtitle: 'When your account was set up',
                      ),
                      const SizedBox(height: 10),
                      _InfoGroup(
                        rows: [
                          _InfoRowData(
                            icon: Icons.calendar_today_rounded,
                            label: 'Account Created',
                            value: _formatDateTime(profile.createdAt),
                          ),
                          _InfoRowData(
                            icon: Icons.devices_rounded,
                            label: 'Device',
                            value: profile.platform?.toUpperCase() ?? 'N/A',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: 'Documents',
                        subtitle: documents.isEmpty
                            ? 'No documents uploaded yet'
                            : '${documents.length} document${documents.length == 1 ? '' : 's'} on file',
                      ),
                      const SizedBox(height: 10),
                      if (documents.isEmpty)
                        const EmptyDocumentsCard()
                      else
                        ...documents.map((doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DocumentStatusCard(
                                title: doc.title ?? 'Untitled Document',
                                issueDate: doc.issueDate,
                                expireDate: doc.expireDate,
                                onTap: () {
                                  if (doc.file != null &&
                                      doc.file!.isNotEmpty) {
                                    Get.to(() => DocumentDownload(
                                        file:
                                            "https://msyard.s3.us-west-1.amazonaws.com/images/${doc.file}"));
                                  }
                                },
                              ),
                            )),
                      const SizedBox(height: 32),
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

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getDaysSince(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final days = DateTime.now().difference(date).inDays;
      return '$days';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _TopHeader extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const _TopHeader({required this.onChangePassword, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 16, 12, 90),
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 22, color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'change_password',
                      height: 40,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.password_rounded,
                                size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'logout',
                      height: 40,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                size: 16, color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'change_password') {
                      onChangePassword();
                    } else if (value == 'logout') {
                      onLogout();
                    }
                  },
                ),
              ],
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

class _ProfileCard extends StatelessWidget {
  final Profiles profile;
  final UserModel user;

  const _ProfileCard({required this.profile, required this.user});

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == 'active';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TColors.navyHeader.withOpacity(0.08),
                  border: Border.all(
                      color: TColors.navyHeader.withOpacity(0.12), width: 3),
                ),
                child: profile.profilePic != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: Image.network(profile.profilePic!,
                            fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          _getInitials(profile.username ?? ''),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: TColors.navyHeader,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    isActive ? Icons.check_rounded : Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.username ?? 'Unknown Driver',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Driver ID: ${user.driverNumber ?? 'N/A'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user.status?.toString().toUpperCase() ?? 'INACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF047857)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _StatsSplitCard extends StatelessWidget {
  final String daysActive;
  final String platform;
  final String version;

  const _StatsSplitCard({
    required this.daysActive,
    required this.platform,
    required this.version,
  });

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
            child: _stat(Icons.calendar_month_rounded, daysActive,
                'Days Active', const Color(0xFF2E5BFF)),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade100),
          Expanded(
            child: _stat(Icons.phone_android_rounded, platform, 'Platform',
                const Color(0xFF9333EA)),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade100),
          Expanded(
            child: _stat(Icons.apps_rounded, version, 'App Version',
                const Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;

  _InfoRowData({required this.icon, required this.label, required this.value});
}

class _InfoGroup extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoGroup({required this.rows});

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
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _row(rows[i]),
            if (i != rows.length - 1)
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

  Widget _row(_InfoRowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TColors.navyHeader.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(row.icon, color: TColors.navyHeader, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
