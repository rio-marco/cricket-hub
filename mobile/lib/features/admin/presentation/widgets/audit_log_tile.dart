import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/admin_audit_log.dart';

class AuditLogTile extends StatelessWidget {
  final AdminAuditLog entry;

  const AuditLogTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor =
        entry.severity.toUpperCase() == 'HIGH' ||
            entry.severity.toUpperCase() == 'CRITICAL'
        ? AppColors.error
        : AppColors.info;
    final timestamp = entry.createdAt == null
        ? ''
        : DateFormat.yMMMd().add_jm().format(entry.createdAt!.toLocal());

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.action,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (entry.severity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (entry.actorName.isNotEmpty) 'By ${entry.actorName}',
              if (entry.entity.isNotEmpty) entry.entity,
              if (entry.entityId.isNotEmpty) entry.entityId,
              if (timestamp.isNotEmpty) timestamp,
            ].join(' • '),
            style: isDark
                ? AppTextStyles.bodySmallDark
                : AppTextStyles.bodySmallLight,
          ),
          if (entry.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.reason,
              style: isDark
                  ? AppTextStyles.bodySmallDark
                  : AppTextStyles.bodySmallLight,
            ),
          ],
        ],
      ),
    );
  }
}
