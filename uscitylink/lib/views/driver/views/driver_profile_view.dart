import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/model/driver_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/driver/widegts/document_status_card.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

const double _kProfileCardOverflow = 130;

/// Faint hairline used to give an otherwise-flat white card a defined edge,
/// so it reads as a distinct raised surface rather than blending into the
/// canvas behind it.
const _kCardEdge = Border.fromBorderSide(
  BorderSide(color: Color(0x0A000000)),
);

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
        backgroundColor: TColors.surfaceCanvas,
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
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Loading profile...',
                    style: AppText.bodySm.copyWith(color: TColors.textMuted),
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
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: 0,
                      child: _ProfileCard(
                        driver: driver,
                        initials: _getInitials(driver?.name ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _kProfileCardOverflow - 120),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactSplitCard(driver: driver),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionLabel(
                        title: 'Basic Information',
                        subtitle: 'Fuel, ELD & PrePass credentials',
                      ),
                      // const SizedBox(height: AppSpacing.md),
                      _BasicInfoGrid(driver: driver),

                      /// const SizedBox(height: AppSpacing.xl),
                      _SectionLabel(
                        title: 'Documents',
                        subtitle: documents.isEmpty
                            ? 'No documents uploaded yet'
                            : '${documents.length} document${documents.length == 1 ? '' : 's'} on file',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (documents.isEmpty)
                        const EmptyDocumentsCard(
                          message: 'This driver has no documents uploaded',
                        )
                      else
                        ...documents.map((doc) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.xxl),
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
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.header),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          topInset + AppSpacing.sm,
          AppSpacing.lg,
          90,
        ),
        decoration: const BoxDecoration(gradient: AppGradients.header),
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
                Expanded(
                  child: Text(
                    'My Information',
                    style: AppText.titleLg.copyWith(color: Colors.white),
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
        color: Colors.white.withValues(alpha: opacity),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TColors.surfaceCard, Color(0xFFF6F4FE)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: _kCardEdge,
        boxShadow: [
          ...AppShadows.raised,
          BoxShadow(
            color: TColors.violet.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TColors.violet.withValues(alpha: 0.20),
                  TColors.violet.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                  color: TColors.violet.withValues(alpha: 0.25), width: 2),
              boxShadow: [
                BoxShadow(
                  color: TColors.violet.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: AppText.headline
                    .copyWith(color: TColors.violetDeep, fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver?.name ?? 'Unknown Driver',
                  style: AppText.headline.copyWith(color: TColors.textStrong),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TColors.violet.withValues(alpha: 0.16),
                        TColors.violet.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                        color: TColors.violet.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_rounded,
                          size: 13, color: TColors.violetDeep),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          driver?.driverNumber ?? 'N/A',
                          style: AppText.numeric(AppText.labelMd)
                              .copyWith(color: TColors.violetDeep),
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 30,
          margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TColors.navyHeaderDeep, TColors.violet],
            ),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.titleLg.copyWith(color: TColors.textStrong),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.bodySm.copyWith(color: TColors.textMuted),
              ),
            ],
          ),
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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TColors.surfaceCard, Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: _kCardEdge,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _half(Icons.email_rounded, driver?.email ?? 'N/A',
                    'Email', TColors.info),
              ),
            ],
          ),
          Divider(height: 1, color: TColors.hairline),
          Row(
            children: [
              Container(width: 1, height: 56, color: TColors.hairline),
              Expanded(
                child: _half(Icons.phone_rounded, driver?.phoneNumber ?? 'N/A',
                    'Phone', TColors.brandGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _half(IconData icon, String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.base,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.20),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: icon == Icons.email_rounded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleMd.copyWith(color: TColors.textStrong),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppText.labelSm.copyWith(color: TColors.textMuted),
              ),
            ],
          )
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _MaskedInfoTile(
          icon: Icons.password_rounded,
          accent: TColors.violet,
          label: 'ELD Password',
          value: driver?.eld_password ?? '-',
        ),
        _InfoTile(
          icon: Icons.local_gas_station_rounded,
          accent: TColors.brandGold,
          label: 'Fuel ID',
          value: driver?.driver_fuel_id ?? '-',
        ),
        _InfoTile(
          icon: Icons.credit_card_rounded,
          accent: TColors.teal,
          label: 'Fuel Card',
          value: driver?.fuel_card_number ?? '-',
        ),
        _InfoTile(
          icon: Icons.verified_user_rounded,
          accent: TColors.brandGreen,
          label: 'Pre Pass ID',
          value: driver?.pre_pass_id ?? '-',
        ),
      ],
    );
  }
}

/// A card with a colored left accent strip (clipped separately from the
/// shadow so the strip's flat color doesn't get soft-edged by it) — the
/// "Stripe/Linear card" pattern that reads as more deliberately designed
/// than a plain flat-white rectangle.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TColors.surfaceCard, Color(0xFFFAFAFC)],
            ),
            border: _kCardEdge,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.22),
                                  accent.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 18, color: accent),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppText.labelMd
                                .copyWith(color: TColors.textMuted),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.titleMd
                                .copyWith(color: TColors.textStrong),
                          ),
                        ],
                      ),
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

/// Same tile as [_InfoTile], but the value is masked behind dots by default
/// with a tap-to-reveal eye icon — used for the ELD password, which
/// shouldn't sit in plaintext on screen. The dot count is fixed rather than
/// matching the real value's length, so a glance at the masked state can't
/// leak how long the password is.
class _MaskedInfoTile extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  const _MaskedInfoTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  @override
  State<_MaskedInfoTile> createState() => _MaskedInfoTileState();
}

class _MaskedInfoTileState extends State<_MaskedInfoTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return _InfoTile(
      icon: widget.icon,
      accent: widget.accent,
      label: widget.label,
      value: _revealed ? widget.value : '••••••••',
      trailing: InkWell(
        onTap: () => setState(() => _revealed = !_revealed),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 16,
            color: TColors.textMuted,
          ),
        ),
      ),
    );
  }
}
