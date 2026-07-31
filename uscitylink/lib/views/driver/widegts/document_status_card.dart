import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    Color statusColor = Colors.grey;
    String statusText = 'N/A';
    if (expiry != null) {
      if (isExpired) {
        statusColor = const Color(0xFFEF4444);
        statusText = 'EXPIRED';
      } else if (daysLeft <= 30) {
        statusColor = const Color(0xFFF59E0B);
        statusText = 'EXPIRING';
      } else {
        statusColor = const Color(0xFF16A34A);
        statusText = 'VALID';
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2E5BFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_rounded,
                  size: 20, color: Color(0xFF2E5BFF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _dateChip('Issued', issue, Colors.blueGrey, false),
                      const SizedBox(width: 12),
                      _dateChip('Expires', expiry, statusColor, isExpired),
                      const Spacer(),
                      if (!isExpired && expiry != null && daysLeft > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: daysLeft <= 30
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$daysLeft days',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: daysLeft <= 30
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF065F46),
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
    );
  }

  Widget _dateChip(String label, DateTime? date, Color color, bool isExpired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 3),
        Text(
          date != null ? DateFormat('MM/dd/yyyy').format(date) : 'N/A',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isExpired ? const Color(0xFFDC2626) : Colors.grey.shade800,
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
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'No Documents',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
