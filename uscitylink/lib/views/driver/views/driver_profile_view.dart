import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/widegts/document_status_card.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

const double _kProfileCardOverflow = 130;

class DriverProfileView extends StatelessWidget {
  DriverProfileView({super.key});

  final LoginController _controller = Get.put(LoginController());
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getDriverProfile();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Obx(() {
          final driver = _controller.driverProfile.value.driver;
          final documents = _controller.driverProfile.value.document ?? [];

          if (_controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: TColors.navyHeader,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

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
                        _Header(
                          onBack: () {
                            Get.back();
                            _dashboardController.getDashboard();
                          },
                        ),
                        const SizedBox(height: _kProfileCardOverflow),
                      ],
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: _ProfileCard(
                        driver: driver,
                        initials: _getInitials(driver?.name ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _kProfileCardOverflow + 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactSplitCard(driver: driver),
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        title: 'Basic Information',
                        subtitle: 'Fuel, ELD & PrePass credentials',
                      ),
                      const SizedBox(height: 10),
                      _BasicInfoGrid(driver: driver),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: 'Documents',
                        subtitle: documents.isEmpty
                            ? 'No documents uploaded yet'
                            : '${documents.length} document${documents.length == 1 ? '' : 's'} on file',
                      ),
                      const SizedBox(height: 10),
                      if (documents.isEmpty)
                        const EmptyDocumentsCard(
                          message: 'This driver has no documents uploaded',
                        )
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
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topInset + 12, 20, 90),
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
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'My Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
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
  final Driver? driver;
  final String initials;

  const _ProfileCard({required this.driver, required this.initials});

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TColors.navyHeader.withOpacity(0.08),
              border: Border.all(
                  color: TColors.navyHeader.withOpacity(0.12), width: 3),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TColors.navyHeader,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver?.name ?? 'Unknown Driver',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 15, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        driver?.driverNumber ?? 'N/A',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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

class _ContactSplitCard extends StatelessWidget {
  final Driver? driver;

  const _ContactSplitCard({required this.driver});

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
            child: _half(Icons.email_rounded, driver?.email ?? 'N/A', 'Email',
                const Color(0xFF2E5BFF)),
          ),
          Container(width: 1, height: 56, color: Colors.grey.shade100),
          Expanded(
            child: _half(Icons.phone_rounded, driver?.phoneNumber ?? 'N/A',
                'Phone', const Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }

  Widget _half(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoGrid extends StatelessWidget {
  final Driver? driver;

  const _BasicInfoGrid({required this.driver});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.password_rounded, 'ELD Password', driver?.eld_password ?? '-'),
      (Icons.local_gas_station_rounded, 'Fuel ID',
          driver?.driver_fuel_id ?? '-'),
      (Icons.credit_card_rounded, 'Fuel Card',
          driver?.fuel_card_number ?? '-'),
      (Icons.verified_user_rounded, 'Pre Pass ID',
          driver?.pre_pass_id ?? '-'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (icon, label, value) = items[index];
        return _tile(icon, label, value);
      },
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TColors.navyHeader.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: TColors.navyHeader),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
