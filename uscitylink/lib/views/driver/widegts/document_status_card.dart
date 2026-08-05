import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';

const _kCardEdge = Border.fromBorderSide(
  BorderSide(color: Color(0x0A000000)),
);

/// Shared "document with expiry" card used across profile/settings screens
/// so every document list in the app reads the same way.
class DocumentStatusCard extends StatelessWidget {
  final String title;
  final String? issueDate;
  final String? expireDate;
  final VoidCallback? onTap;

  const DocumentStatusCard({
    super.key,
    required this.title,
    required this.onTap,
    this.issueDate,
    this.expireDate,
  });

  @override
  Widget build(BuildContext context) {
    final issue = DateTime.tryParse(issueDate ?? '');
    final expiry = DateTime.tryParse(expireDate ?? '');
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final daysLeft = expiry?.difference(DateTime.now()).inDays ?? 0;

    Color statusColor = TColors.textMuted;
    String statusText = 'N/A';
    if (expiry != null) {
      if (isExpired) {
        statusColor = TColors.error;
        statusText = 'EXPIRED';
      } else if (daysLeft <= 30) {
        statusColor = TColors.warning;
        statusText = 'EXPIRING';
      } else {
        statusColor = TColors.success;
        statusText = 'VALID';
      }
    }

    // Outer container carries the shadow (unclipped, so it isn't cut off);
    // the inner ClipRRect carries the gradient fill + colored left strip, so
    // the strip's edge stays crisp instead of being softened by the shadow
    // blur.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TColors.surfaceCard, Color(0xFFFAFAFC)],
                ),
                border: _kCardEdge,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: statusColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    TColors.navyHeaderDeep
                                        .withValues(alpha: 0.16),
                                    TColors.navyHeaderDeep
                                        .withValues(alpha: 0.06),
                                  ],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.md),
                                boxShadow: [
                                  BoxShadow(
                                    color: TColors.navyHeaderDeep
                                        .withValues(alpha: 0.14),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                size: 20,
                                color: TColors.navyHeaderDeep,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: AppText.titleMd.copyWith(
                                              color: TColors.textStrong),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                              alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: statusColor.withValues(
                                                alpha: 0.22),
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: AppText.labelSm
                                              .copyWith(color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      _dateChip('Issued', issue,
                                          TColors.textBody, false),
                                      const SizedBox(width: AppSpacing.md),
                                      _dateChip('Expires', expiry, statusColor,
                                          isExpired),
                                      const Spacer(),
                                      if (!isExpired &&
                                          expiry != null &&
                                          daysLeft > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (daysLeft <= 30
                                                    ? TColors.warning
                                                    : TColors.success)
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                                AppRadii.pill),
                                          ),
                                          child: Text(
                                            '$daysLeft days',
                                            style: AppText.labelSm.copyWith(
                                              color: daysLeft <= 30
                                                  ? TColors.warning
                                                  : TColors.success,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateChip(String label, DateTime? date, Color color, bool isExpired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelSm.copyWith(color: TColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          date != null ? DateFormat('MM/dd/yyyy').format(date) : 'N/A',
          style: AppText.numeric(AppText.bodySm).copyWith(
            fontWeight: FontWeight.w600,
            color: isExpired ? TColors.error : TColors.textBody,
          ),
        ),
      ],
    );
  }
}

/// Shared empty-state card for a documents list.
class EmptyDocumentsCard extends StatelessWidget {
  final String message;

  const EmptyDocumentsCard({
    super.key,
    this.message = 'You have no documents uploaded yet',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
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
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 44,
            color: TColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Documents',
            style: AppText.titleMd.copyWith(color: TColors.textBody),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppText.bodySm.copyWith(color: TColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
