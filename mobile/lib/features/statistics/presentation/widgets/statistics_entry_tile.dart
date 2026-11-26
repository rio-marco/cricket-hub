import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/leaderboard_entry.dart';

class StatisticsEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final VoidCallback? onTap;

  const StatisticsEntryTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = entry.rank == 1
        ? AppColors.trophyGold
        : entry.rank == 2
            ? AppColors.trophySilver
            : entry.rank == 3
                ? AppColors.trophyBronze
                : AppColors.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${entry.rank}',
              style: (isDark
                      ? AppTextStyles.titleSmallDark
                      : AppTextStyles.titleSmallLight)
                  .copyWith(color: rankColor, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isDark
                      ? AppTextStyles.titleSmallDark
                      : AppTextStyles.titleSmallLight,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (entry.jerseyNumber != null) '#${entry.jerseyNumber}',
                    if (entry.playingRole.isNotEmpty) entry.playingRole,
                    if (entry.city.isNotEmpty) entry.city,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: isDark
                      ? AppTextStyles.bodySmallDark
                      : AppTextStyles.bodySmallLight,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.valueDisplay,
            style: (isDark
                    ? AppTextStyles.titleLargeDark
                    : AppTextStyles.titleLargeLight)
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
