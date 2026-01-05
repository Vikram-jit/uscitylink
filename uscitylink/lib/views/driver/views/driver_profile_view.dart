import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class DriverProfileView extends StatelessWidget {
  DriverProfileView({super.key});

  final LoginController _controller = Get.put(LoginController());
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getDriverProfile();
    });

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Obx(() {
        final driver = _controller.driverProfile.value.driver;
        final documents = _controller.driverProfile.value.document ?? [];

        if (_controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: TColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading profile...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.grey[800],
                ),
                onPressed: () {
                  Get.back();
                  _dashboardController.getDashboard();
                },
              ),
              title: Text(
                "${_controller.driverProfile.value.driver?.name ?? ""}",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                  letterSpacing: -0.3,
                ),
              ),
              centerTitle: true,
              actions: [],
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: _buildProfileHeader(context, driver),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: _buildQuickStats(driver),
            ),

            // Basic Information
            SliverToBoxAdapter(
              child: _buildSectionTitle('Basic Information'),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _buildBasicInfoGrid(driver),
              ),
            ),

            // Documents Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Documents'),
            ),

            documents.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyDocuments(),
                  )
                : SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildDocumentItem(documents[index]);
                        },
                        childCount: documents.length,
                      ),
                    ),
                  ),

            // Bottom Spacing
            SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Driver? driver) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TColors.primary.withOpacity(0.2),
                  TColors.primary.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: TColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(driver?.name ?? ''),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: TColors.primary,
                ),
              ),
            ),
          ),

          SizedBox(width: 20),

          // Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver?.name ?? 'Unknown Driver',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 6),
                    Text(
                      driver?.driverNumber ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Driver? driver) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.email_rounded,
              value: driver?.email?.split('@').first ?? 'N/A',
              label: 'Email',
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.phone_rounded,
              value: driver?.phoneNumber ?? 'N/A',
              label: 'Phone',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.grey[900],
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildBasicInfoGrid(Driver? driver) {
    final List<Map<String, dynamic>> infoItems = [
      {
        'icon': Icons.password_rounded,
        'label': 'ELD Password',
        'value': driver?.eld_password ?? '-',
      },
      {
        'icon': Icons.local_gas_station_rounded,
        'label': 'Fuel ID',
        'value': driver?.driver_fuel_id ?? '-',
      },
      {
        'icon': Icons.credit_card_rounded,
        'label': 'Fuel Card',
        'value': driver?.fuel_card_number ?? '-',
      },
      {
        'icon': Icons.verified_user_rounded,
        'label': 'Pre Pass ID',
        'value': driver?.pre_pass_id ?? '-',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: infoItems.length,
      itemBuilder: (context, index) {
        final item = infoItems[index];
        return _buildInfoTile(
          icon: item['icon'],
          label: item['label'],
          value: item['value'],
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: TColors.primary,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(Document doc) {
    final issueDate = DateTime.tryParse(doc.issueDate ?? '');
    final expireDate = DateTime.tryParse(doc.expireDate ?? '');
    final isExpired = expireDate != null && expireDate.isBefore(DateTime.now());
    final daysLeft = expireDate?.difference(DateTime.now()).inDays ?? 0;

    // Determine status
    String statusText = 'VALID';
    Color statusColor = Colors.green;
    Color statusBgColor = Colors.green.withOpacity(0.1);

    if (isExpired) {
      statusText = 'EXPIRED';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    } else if (daysLeft <= 30) {
      statusText = 'EXPIRING SOON';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: () {
        print("${Constant.aws}/${doc.file}");
        if (doc.file != null && doc.file!.isNotEmpty) {
          Get.to(() => DocumentDownload(
              file:
                  "https://msyard.s3.us-west-1.amazonaws.com/images/${doc.file}"));
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Document Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_rounded,
                size: 24,
                color: TColors.primary,
              ),
            ),

            SizedBox(width: 16),

            // Document Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.title ?? 'Untitled Document',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
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

                  SizedBox(height: 8),

                  // Dates
                  Row(
                    children: [
                      // Issue Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 6),
                          Text(
                            issueDate != null
                                ? DateFormat('MM/dd/yyyy').format(issueDate)
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 16),

                      // Expiry Date
                      Row(
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            expireDate != null
                                ? DateFormat('MM/dd/yyyy').format(expireDate)
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (!isExpired && daysLeft > 0) ...[
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: daysLeft / 365,
                      backgroundColor: Colors.grey[200],
                      color: daysLeft <= 30 ? Colors.orange : Colors.green,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$daysLeft days remaining',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDocuments() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
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

  void _showLogoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 24,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Are you sure you want to logout from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _controller.logOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
