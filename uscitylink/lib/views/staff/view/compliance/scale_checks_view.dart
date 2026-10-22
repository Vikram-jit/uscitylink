import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/controller/staff/compliance_controller.dart';
import 'package:uscitylink/model/staff/compliance_models.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/view/compliance/compliance_widgets.dart';
import 'package:uscitylink/views/staff/view/compliance/scale_check_detail_view.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';

/// Compliance → Scale checks: every CAT ticket the agent checked, filtered to the ones waiting for
/// a dispatcher by default (same as the web page).
class ScaleChecksView extends StatefulWidget {
  const ScaleChecksView({super.key});

  @override
  State<ScaleChecksView> createState() => _ScaleChecksViewState();
}

class _ScaleChecksViewState extends State<ScaleChecksView> with SingleTickerProviderStateMixin {
  final ComplianceController _controller = Get.put(ComplianceController());
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabs.index = _controller.filter.value == 'pending' ? 0 : 1;
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _controller.setFilter(_tabs.index == 0 ? 'pending' : '');
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) _controller.loadMore();
    });
    _controller.loadChecks();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        backgroundColor: StaffColors.canvas,
        body: Column(
          children: [
            StaffHeader(
              title: 'Scale checks',
              subtitle: 'CAT tickets checked against route rules',
              leadingIcon: Icons.arrow_back_rounded,
              onLeading: () => Get.back(),
              bottom: Obx(() {
                final pending = _controller.pendingCount.value;
                return StaffSegmentedTabs(
                  controller: _tabs,
                  labels: [pending > 0 ? 'Waiting ($pending)' : 'Waiting', 'All tickets'],
                );
              }),
            ),
            Expanded(
              child: RefreshIndicator(
                color: StaffColors.primary,
                onRefresh: () => _controller.loadChecks(),
                child: Obx(() {
                  final checks = _controller.checks;
                  if (_controller.loading.value && checks.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: StaffColors.primary));
                  }
                  if (checks.isEmpty) {
                    return StaffEmptyState(
                      icon: Icons.scale_outlined,
                      title: _controller.filter.value == 'pending' ? 'Nothing is waiting' : 'No scale tickets yet',
                      message: _controller.filter.value == 'pending'
                          ? 'Tickets that need a dispatcher to release them show up here.'
                          : 'Scale tickets drivers send are checked automatically.',
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.xxl),
                    itemCount: checks.length + (_controller.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= checks.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.base),
                          child: Center(child: CircularProgressIndicator(color: StaffColors.primary)),
                        );
                      }
                      return _ScaleCheckTile(check: checks[i]);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleCheckTile extends StatelessWidget {
  final ScaleCheck check;
  const _ScaleCheckTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final w = check.weights;
    final when = check.createdAt == null ? '' : DateFormat('MMM d, h:mm a').format(check.createdAt!);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.md), boxShadow: AppShadows.card),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => Get.to(() => ScaleCheckDetailView(check: check)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StaffAvatar(name: check.driverName, icon: Icons.scale_rounded, size: 42),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(check.driverName ?? 'Driver',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.titleMd.copyWith(color: StaffColors.textStrong)),
                          Text(
                            [if (check.truck != null) 'Truck ${check.truck}', when].where((s) => s.isNotEmpty).join(' · '),
                            style: AppText.bodySm.copyWith(color: StaffColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: StaffColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'S ${lb(w['steer'])} · D ${lb(w['drive'])} · T ${lb(w['trailer'])} · G ${lb(w['gross'])}',
                  style: AppText.numeric(AppText.labelLg).copyWith(color: StaffColors.textBody),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ScaleStatusPill(check: check),
                    ApprovalPill(check: check),
                    if (check.previousCheckId != null) const StaffPill(label: 'Reweigh', color: StaffColors.textBody),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
