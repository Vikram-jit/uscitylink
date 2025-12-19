import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/hive_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/model/user_model.dart';
import 'package:uscitylink/model/vehicle_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/services/socket_service.dart';

import '../../../model/login_model.dart';

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
  HiveController _hiveController = Get.find<HiveController>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this as WidgetsBindingObserver);
    // TODO: implement initState
    super.initState();
    loginController.getProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        //if (_hiveController.isProcessing.value == false) {
        socketService.socket.disconnect();
//}
      }
      print("App is in the background");
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
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Driver Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 22, color: Colors.grey[700]),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context) {
                return [
                  // Change Password Option
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
                          child: Icon(
                            Icons.password_rounded,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
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

                  // Divider
                  PopupMenuDivider(height: 1),

                  // Logout Option
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
                          child: Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(width: 12),
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
                ];
              },
              onSelected: (String value) {
                if (value == 'change_password') {
                  Get.toNamed(AppRoutes.driverChangePassword);
                } else if (value == 'logout') {}
              },
            ),
          ],
        ),
        body: Obx(() {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 16),

                    // Profile Header Card
                    _buildProfileHeader(loginController.userProfile.value,
                        loginController.userProfile.value.user ?? UserModel()),

                    SizedBox(height: 24),

                    // Quick Stats Row
                    _buildQuickStats(loginController.userProfile.value),

                    SizedBox(height: 24),
                  ],
                ),
              ),

              // Driver Information Section
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Driver Information'),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(
                        loginController.userProfile.value.user ?? UserModel(),
                        loginController.userProfile.value.role ?? Role()),
                    SizedBox(height: 20),
                  ]),
                ),
              ),

              // Account Details Section
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Account Details'),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAccountCard(loginController.userProfile.value),
                    SizedBox(height: 20),
                  ]),
                ),
              ),

              // Documents Section
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Documents'),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: loginController.userProfile.value.documents == null ||
                        loginController.userProfile.value.documents!.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyDocuments(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildDocumentTile(
                              loginController
                                  .userProfile.value.documents![index],
                              isLast: index ==
                                  loginController
                                          .userProfile.value.documents!.length -
                                      1,
                            );
                          },
                          childCount: loginController
                              .userProfile.value.documents!.length,
                        ),
                      ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        }));
  }

  Widget _buildProfileHeader(Profiles userData, UserModel user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  border: Border.all(
                    // color: Colors.grey[200],
                    width: 3,
                  ),
                ),
                child: userData.profilePic != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.network(
                          userData.profilePic!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(userData.username ?? ''),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
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
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Name and Driver Number
          Text(
            userData.username ?? 'Unknown Driver',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Driver ID: ${user.driverNumber ?? 'N/A'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 16),

          // Status Chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: user.status == 'active'
                  ? Color(0xFFDCFCE7)
                  : Color(0xFFFEE2E2),
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
                    color: user.status == 'active'
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  user.status?.toString().toUpperCase() ?? 'INACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.status == 'active'
                        ? Color(0xFF047857)
                        : Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Profiles userData) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_month_rounded,
              value: _getDaysSince(userData.createdAt),
              label: 'Days Active',
              color: Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              icon: Icons.phone_android_rounded,
              value: userData.platform?.toString().toUpperCase() ?? 'N/A',
              label: 'Platform',
              color: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              icon: Icons.apps_rounded,
              value: userData.version ?? 'N/A',
              label: 'App Version',
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInfoCard(UserModel user, Role role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone Number',
            value: user.phoneNumber ?? 'N/A',
            isFirst: true,
          ),
          _buildInfoRow(
            icon: Icons.email_rounded,
            label: 'Email Address',
            value: user.email ?? 'N/A',
          ),
          _buildInfoRow(
            icon: Icons.location_city_rounded,
            label: 'Yard ID',
            value: user.yardId?.toString() ?? 'N/A',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Profiles userData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Account Created',
            value: _formatDateTime(userData.createdAt),
            isFirst: true,
          ),
          // _buildInfoRow(
          //   icon: Icons.update_rounded,
          //   label: 'Last Updated',
          //   value: _formatDateTime(userData['updatedAt']),
          // ),
          // _buildInfoRow(
          //   icon: Icons.login_rounded,
          //   label: 'Last Login',
          //   value: _formatDateTime(userData['last_login']),
          // ),
          _buildInfoRow(
            icon: Icons.devices_rounded,
            label: 'Device',
            value: userData.platform?.toString().toUpperCase() ?? 'N/A',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
          bottom:
              isLast ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(Documents doc, {bool isLast = false}) {
    final issueDate = DateTime.tryParse(doc.issueDate ?? '');
    final expireDate = DateTime.tryParse(doc.expireDate ?? '');
    final isExpired = expireDate != null && expireDate.isBefore(DateTime.now());
    final daysLeft = expireDate?.difference(DateTime.now()).inDays ?? 0;

    Color statusColor = Colors.grey;
    String statusText = 'N/A';

    if (expireDate != null) {
      if (isExpired) {
        statusColor = Color(0xFFEF4444);
        statusText = 'EXPIRED';
      } else if (daysLeft <= 30) {
        statusColor = Color(0xFFF59E0B);
        statusText = 'EXPIRING';
      } else {
        statusColor = Color(0xFF10B981);
        statusText = 'VALID';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            doc.title ?? 'Untitled Document',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Dates Row
                    Row(
                      children: [
                        // Issue Date
                        _buildDateChip(
                          icon: Icons.calendar_today_rounded,
                          label: 'Issued',
                          date: issueDate,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 12),

                        // Expiry Date
                        _buildDateChip(
                          icon: Icons.timer_rounded,
                          label: 'Expires',
                          date: expireDate,
                          color: statusColor,
                          isExpired: isExpired,
                        ),

                        Spacer(),

                        // Days Left Counter
                        if (!isExpired && daysLeft > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: daysLeft <= 30
                                  ? Color(0xFFFEF3C7)
                                  : Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$daysLeft days',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: daysLeft <= 30
                                    ? Color(0xFF92400E)
                                    : Color(0xFF065F46),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // File Name Row
                    Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "https://msyard.s3.us-west-1.amazonaws.com/images/${doc.file}" ??
                                'No file',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.visibility_rounded,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            // View document
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    DateTime? date,
    required Color color,
    bool isExpired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: isExpired ? Colors.red[400] : color,
            ),
            SizedBox(width: 4),
            Text(
              date != null ? DateFormat('dd/MM/yy').format(date) : 'N/A',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isExpired ? Colors.red[600] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyDocuments() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This driver has no documents uploaded',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
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
