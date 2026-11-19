import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/player.dart';

/// Reusable player summary card for listings, leaderboards, and auction sheets.
class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.player,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player Avatar
                    _buildAvatar(isDark),
                    const SizedBox(width: 14),

                    // Player Name and Role Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  player.name,
                                  style: (isDark
                                          ? AppTextStyles.titleMediumDark
                                          : AppTextStyles.titleMediumLight)
                                      .copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (player.jerseyNumber != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${player.jerseyNumber}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Role badge & City
                          Row(
                            children: [
                              _buildRolePill(player.playingRole),
                              if (player.city != null &&
                                  player.city!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    player.city!,
                                    style: (isDark
                                            ? AppTextStyles.bodySmallDark
                                            : AppTextStyles.bodySmallLight)
                                        .copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Batting / Bowling summary text
                          Text(
                            '${player.battingStyleDisplay} • ${player.bowlingStyleDisplay}',
                            style: (isDark
                                    ? AppTextStyles.bodySmallDark
                                    : AppTextStyles.bodySmallLight)
                                .copyWith(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textDisabledDark
                                  : AppColors.textDisabledLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textDisabledDark
                          : AppColors.textDisabledLight,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Key Stats Row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(
                        'Matches',
                        '${player.matchesCount}',
                        isDark,
                      ),
                      _buildDivider(isDark),
                      _buildMiniStat(
                        'Runs',
                        '${player.runs}',
                        isDark,
                        color: AppColors.primary,
                      ),
                      _buildDivider(isDark),
                      _buildMiniStat(
                        'Wickets',
                        '${player.wickets}',
                        isDark,
                        color: AppColors.secondaryLight,
                      ),
                      _buildDivider(isDark),
                      _buildMiniStat(
                        'Avg',
                        player.battingAverage > 0
                            ? player.battingAverage.toStringAsFixed(1)
                            : '-',
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    if (player.avatar != null && player.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(player.avatar!),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        player.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRolePill(String role) {
    Color bg;
    Color fg;
    String label = player.roleDisplay;

    switch (role.toUpperCase()) {
      case 'BATSMAN':
        bg = AppColors.boundaryFour.withOpacity(0.12);
        fg = AppColors.boundaryFour;
        break;
      case 'BOWLER':
        bg = AppColors.pitchGreen.withOpacity(0.12);
        fg = AppColors.pitchGreen;
        break;
      case 'ALL_ROUNDER':
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
        break;
      case 'WICKETKEEPER':
        bg = AppColors.boundarySix.withOpacity(0.12);
        fg = AppColors.boundarySix;
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    );
  }
}
