import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/statistics_provider.dart';
import '../widgets/statistics_entry_tile.dart';
import '../widgets/statistics_filter_bar.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);

    return AppScaffold(
      title: 'Leaderboard',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final metric in leaderboardMetrics)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_metricLabel(metric)),
                            selected: state.metric == metric,
                            onSelected: (_) => notifier.setMetric(metric),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StatisticsFilterBar(
                  filter: state.filter,
                  onChanged: notifier.setFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.load(refresh: true),
              child: _LeaderboardList(state: state, notifier: notifier),
            ),
          ),
        ],
      ),
    );
  }

  String _metricLabel(String metric) {
    switch (metric) {
      case 'runs':
        return 'Runs';
      case 'wickets':
        return 'Wickets';
      case 'battingAverage':
        return 'Batting Avg';
      case 'battingStrikeRate':
        return 'Strike Rate';
      case 'bowlingEconomy':
        return 'Economy';
      case 'bowlingAverage':
        return 'Bowling Avg';
      case 'sixes':
        return 'Sixes';
      case 'fours':
        return 'Fours';
      case 'catches':
        return 'Catches';
      default:
        return metric;
    }
  }
}

class _LeaderboardList extends StatelessWidget {
  final LeaderboardState state;
  final LeaderboardNotifier notifier;

  const _LeaderboardList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.entries.isEmpty) {
      return const LoadingWidget(message: 'Loading leaderboard...');
    }

    if (state.errorMessage != null && state.entries.isEmpty) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () => notifier.load(refresh: true),
      );
    }

    if (state.entries.isEmpty) {
      return EmptyStateWidget(
        title: 'No ranked players',
        subtitle: 'Complete a match to populate this leaderboard.',
        icon: Icons.leaderboard_rounded,
        actionText: 'Refresh',
        actionIcon: Icons.refresh_rounded,
        onActionPressed: () => notifier.load(refresh: true),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.entries.length + (state.hasNextPage ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == state.entries.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: OutlinedButton.icon(
              onPressed: state.isLoadingMore ? null : () => notifier.load(),
              icon: state.isLoadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: const Text('Load more'),
            ),
          );
        }

        final entry = state.entries[index];
        return StatisticsEntryTile(
          entry: entry,
          onTap: () => context.push('/players/${entry.playerId}'),
        );
      },
    );
  }
}
