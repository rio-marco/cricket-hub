import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../players/presentation/widgets/stats_card.dart';
import '../providers/statistics_provider.dart';

class PlayerStatisticsPanel extends ConsumerWidget {
  final String playerId;

  const PlayerStatisticsPanel({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatisticsProvider(playerId));

    return statsAsync.when(
      loading: () => const LoadingWidget(message: 'Loading career statistics...'),
      error: (error, _) => AppErrorWidget(
        title: 'Statistics unavailable',
        message: error.toString(),
        onRetry: () => ref.invalidate(playerStatisticsProvider(playerId)),
      ),
      data: (stats) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AppCard(
          headerTitle: 'Career Statistics',
          headerSubtitle: '${stats.matches} matches • ${stats.playerOfMatch} player of match',
          hasGradientHeader: true,
          headerLeading: const Icon(Icons.bar_chart_rounded, color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Runs',
                      value: '${stats.batting.runs}',
                      subtitle: '${stats.batting.innings} innings',
                      icon: Icons.sports_cricket,
                      hasGradient: true,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Batting Avg',
                      value: stats.batting.average.toStringAsFixed(2),
                      icon: Icons.analytics_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Strike Rate',
                      value: stats.batting.strikeRate.toStringAsFixed(2),
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Wickets',
                      value: '${stats.bowling.wickets}',
                      subtitle: stats.bowling.oversLabel,
                      icon: Icons.sports_baseball,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Economy',
                      value: stats.bowling.economy.toStringAsFixed(2),
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: StatsCard(
                      label: 'Catches',
                      value: '${stats.fielding.catches}',
                      icon: Icons.front_hand_outlined,
                    ),
                  ),
                ],
              ),
              if (stats.recentForm.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Recent Form',
                  style: isDark
                      ? AppTextStyles.titleSmallDark
                      : AppTextStyles.titleSmallLight,
                ),
                const SizedBox(height: 8),
                ...stats.recentForm.map(
                  (performance) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_cricket_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            performance.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: isDark
                                ? AppTextStyles.bodySmallDark
                                : AppTextStyles.bodySmallLight,
                          ),
                        ),
                        Text(
                          '${performance.batting.runs}/${performance.batting.balls} • ${performance.bowling.wickets} wkt',
                          style: isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmallLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
