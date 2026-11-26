import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_player.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminPlayersScreen extends ConsumerWidget {
  const AdminPlayersScreen({super.key});

  static const List<String> _roles = <String>[
    'BATSMAN',
    'BOWLER',
    'ALL_ROUNDER',
    'WICKET_KEEPER',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminPlayersProvider);

    return AppScaffold(
      title: 'Admin Players',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminPlayersProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminFilterBar(
                search: state.search,
                status: state.status,
                statuses: _roles,
                statusLabel: 'Role',
                onSearchChanged: (value) =>
                    ref.read(adminPlayersProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminPlayersProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading players...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminPlayersProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No players found',
                  icon: Icons.sports_cricket_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Players',
                  subtitle: '${state.total} total',
                  onRefresh: () => ref
                      .read(adminPlayersProvider.notifier)
                      .load(refresh: true),
                  children: [
                    for (final player in state.items) ...[
                      _PlayerCard(player: player),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () =>
                            ref.read(adminPlayersProvider.notifier).loadMore(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends ConsumerStatefulWidget {
  final AdminPlayer player;

  const _PlayerCard({required this.player});

  @override
  ConsumerState<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends ConsumerState<_PlayerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminPlayerDetailProvider(widget.player.id))
        : null;
    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(
            widget.player.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              widget.player.role,
              widget.player.teamName,
              '${widget.player.runs} runs',
              '${widget.player.wickets} wickets',
            ].where((value) => value.isNotEmpty).join(' • '),
          ),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Matches: ${widget.player.matchesPlayed}'),
                  Text(
                    'User ID: ${widget.player.userId.isEmpty ? '-' : widget.player.userId}',
                  ),
                  if (detail != null)
                    detail.when(
                      data: (player) => Text('Details: ${player.raw}'),
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (error, _) => Text('Details unavailable: $error'),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
