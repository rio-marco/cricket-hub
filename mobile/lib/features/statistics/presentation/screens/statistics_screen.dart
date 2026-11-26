import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/statistics_overview.dart';
import '../providers/statistics_provider.dart';
import '../widgets/statistics_entry_tile.dart';
import '../widgets/statistics_filter_bar.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsOverviewProvider);
    final notifier = ref.read(statisticsOverviewProvider.notifier);

    return AppScaffold(
      title: 'Statistics & Analytics',
      body: RefreshIndicator(
        onRefresh: () => notifier.load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            StatisticsFilterBar(
              filter: state.filter,
              onChanged: notifier.setFilter,
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.overview == null)
              const LoadingWidget(message: 'Loading statistics...')
            else if (state.errorMessage != null && state.overview == null)
              AppErrorWidget(
                message: state.errorMessage!,
                onRetry: () => notifier.load(refresh: true),
              )
            else if (state.overview != null)
              _OverviewContent(overview: state.overview!),
          ],
        ),
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  final StatisticsOverview overview;

  const _OverviewContent({required this.overview});

  @override
  Widget build(BuildContext context) {
    if (overview.isEmpty) {
      return const EmptyStateWidget(
        title: 'No statistics yet',
        subtitle: 'Completed matches with valid innings will appear here.',
        icon: Icons.bar_chart_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EntrySection(
          title: 'Top Run Scorers',
          icon: Icons.sports_cricket,
          entries: overview.topBatsmen,
        ),
        _EntrySection(
          title: 'Top Wicket Takers',
          icon: Icons.sports_baseball,
          entries: overview.topBowlers,
        ),
        _EntrySection(
          title: 'Top Fielders',
          icon: Icons.front_hand_outlined,
          entries: overview.topFielders,
        ),
      ],
    );
  }
}

class _EntrySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<LeaderboardEntry> entries;

  const _EntrySection({
    required this.title,
    required this.icon,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StatisticsEntryTile(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}
