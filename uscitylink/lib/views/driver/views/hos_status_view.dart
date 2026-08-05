import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/hos_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

/// Real-time Hours of Service — drive time left, on-duty/cycle clocks, and
/// today's duty status, sourced from Samsara via `GET /user/hos-status`.
/// Pushed from the dashboard's "This Week" card; not a bottom-nav tab.
class HosStatusView extends StatefulWidget {
  const HosStatusView({super.key});

  @override
  State<HosStatusView> createState() => _HosStatusViewState();
}

class _HosStatusViewState extends State<HosStatusView> {
  final HosController _hosController = Get.put(HosController());

  @override
  void initState() {
    super.initState();
    _hosController.getHosStatus();
  }

  @override
  void dispose() {
    Get.delete<HosController>();
    super.dispose();
  }

  String _fmtHm(int? minutes) {
    if (minutes == null) return '—:—';
    final m = minutes < 0 ? 0 : minutes;
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  String _fmtSince(String? isoTime) {
    if (isoTime == null) return '—';
    final parsed = DateTime.tryParse(isoTime);
    if (parsed == null) return '—';
    return DateFormat('h:mm a').format(parsed.toLocal());
  }

  ({String label, Color color, IconData icon}) _dutyStatusMeta(String? status) {
    switch (status) {
      case 'driving':
        return (
          label: 'Driving',
          color: TColors.brandGreen,
          icon: Icons.local_shipping_rounded
        );
      case 'onDuty':
        return (
          label: 'On Duty',
          color: TColors.brandGreen,
          icon: Icons.badge_rounded
        );
      case 'sleeperBed':
        return (
          label: 'Sleeper Berth',
          color: TColors.brandGold,
          icon: Icons.hotel_rounded
        );
      case 'yardMove':
        return (
          label: 'Yard Move',
          color: TColors.brandGold,
          icon: Icons.sync_alt_rounded
        );
      case 'personalConveyance':
        return (
          label: 'Personal Conveyance',
          color: TColors.brandGold,
          icon: Icons.directions_car_rounded
        );
      case 'offDuty':
        return (
          label: 'Off Duty',
          color: TColors.textMuted,
          icon: Icons.bedtime_rounded
        );
      default:
        return (
          label: 'Unknown',
          color: TColors.textMuted,
          icon: Icons.help_outline_rounded
        );
    }
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
        backgroundColor: TColors.surfaceCanvas,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          backgroundColor: TColors.navyHeader,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          title: Text('Hours of Service',
              style: AppText.titleLg.copyWith(color: Colors.white)),
        ),
        body: Obx(() {
          if (_hosController.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: TColors.navyHeader),
            );
          }

          final hos = _hosController.hosStatus.value;
          final dutyMeta = _dutyStatusMeta(hos.dutyStatus);
          final driveFraction = (hos.driveRemainingMinutes != null &&
                  hos.driveLimitMinutes != null &&
                  hos.driveLimitMinutes! > 0)
              ? (hos.driveRemainingMinutes! / hos.driveLimitMinutes!)
                  .clamp(0.0, 1.0)
              : 0.0;
          final ringColor = driveFraction >= 0.3
              ? TColors.brandGreen
              : driveFraction >= 0.15
                  ? TColors.brandGold
                  : TColors.brandRed;
          final cycleFraction = (hos.cycleUsedMinutes != null &&
                  hos.cycleLimitMinutes != null &&
                  hos.cycleLimitMinutes! > 0)
              ? (hos.cycleUsedMinutes! / hos.cycleLimitMinutes!).clamp(0.0, 1.0)
              : 0.0;

          return RefreshIndicator(
            onRefresh: () async => _hosController.getHosStatus(),
            color: TColors.navyHeaderDeep,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    decoration: BoxDecoration(
                      color: TColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: _DriveTimeRing(
                            fraction: driveFraction,
                            color: ringColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Drive Time Left',
                                  style: AppText.bodySm
                                      .copyWith(color: TColors.textMuted),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _fmtHm(hos.driveRemainingMinutes),
                                  style: AppText.numeric(
                                    AppText.displayLg.copyWith(
                                      color: TColors.textStrong,
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'HRS',
                                  style: AppText.labelSm
                                      .copyWith(color: TColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            _statColumn(
                                'Driving', _fmtHm(hos.driveElapsedMinutes)),
                            _statDivider(),
                            _statColumn(
                                'On Duty', _fmtHm(hos.onDutyElapsedMinutes)),
                            _statDivider(),
                            _statColumn('Cycle Left',
                                _fmtHm(hos.cycleRemainingMinutes)),
                            _statDivider(),
                            _statColumn('Break In', _fmtHm(hos.breakInMinutes)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    "TODAY'S STATUS",
                    style: AppText.labelSm.copyWith(
                      color: TColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: BoxDecoration(
                      color: TColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(dutyMeta.icon,
                                color: dutyMeta.color, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                dutyMeta.label,
                                style: AppText.titleMd
                                    .copyWith(color: TColors.textStrong),
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: dutyMeta.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              'Since ${_fmtSince(hos.dutyStatusSince)}',
                              style: AppText.bodySm
                                  .copyWith(color: TColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(height: 1, color: TColors.hairline),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Text(
                              'Cycle',
                              style: AppText.bodyMd
                                  .copyWith(color: TColors.textBody),
                            ),
                            const Spacer(),
                            Text(
                              hos.cycleLabel ?? '—',
                              style: AppText.titleMd
                                  .copyWith(color: TColors.textStrong),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Row(
                          children: [
                            Text(
                              'Cycle Used',
                              style: AppText.bodySm
                                  .copyWith(color: TColors.textMuted),
                            ),
                            const Spacer(),
                            Text(
                              '${_fmtHm(hos.cycleUsedMinutes)} / ${_fmtHm(hos.cycleLimitMinutes)}',
                              style: AppText.numeric(AppText.bodySm)
                                  .copyWith(color: TColors.textStrong),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: LinearProgressIndicator(
                            value: cycleFraction,
                            minHeight: 6,
                            backgroundColor: TColors.hairline,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              TColors.brandGreen,
                            ),
                          ),
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

  Widget _statColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelMd.copyWith(color: TColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            style: AppText.numeric(AppText.titleMd)
                .copyWith(color: TColors.textStrong),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 32, color: TColors.hairline);
  }
}

/// Background + progress ring, drawn with two arcs (full grey ring, then a
/// colored arc sweeping clockwise from the top by [fraction]) — the same
/// approach as `_RouteLinesPainter` elsewhere in this app, just a ring
/// instead of freeform strokes.
class _DriveTimeRing extends StatelessWidget {
  final double fraction;
  final Color color;
  final Widget child;

  const _DriveTimeRing({
    required this.fraction,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(fraction: fraction, color: color),
      child: Center(child: child),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = TColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
