import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_json.dart';
import '../../domain/entities/admin_tournament.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminTournamentsScreen extends ConsumerWidget {
  const AdminTournamentsScreen({super.key});

  static const List<String> _statuses = <String>[
    'DRAFT',
    'REGISTRATION',
    'ONGOING',
    'COMPLETED',
    'CANCELLED',
  ];
  static const List<String> _decisions = <String>['APPROVE', 'REJECT'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminTournamentsProvider);
    ref.listen<AdminActionState>(adminActionProvider, (previous, next) {
      final message = next.successMessage ?? next.errorMessage;
      if (message != null &&
          message != previous?.successMessage &&
          message != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return AppScaffold(
      title: 'Admin Tournaments',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminTournamentsProvider.notifier).load(refresh: true),
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
                statuses: _statuses,
                onSearchChanged: (value) => ref
                    .read(adminTournamentsProvider.notifier)
                    .setSearch(value),
                onStatusChanged: (value) => ref
                    .read(adminTournamentsProvider.notifier)
                    .setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading tournaments...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminTournamentsProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No tournaments found',
                  icon: Icons.emoji_events_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Tournaments',
                  subtitle: '${state.total} total',
                  onRefresh: () => ref
                      .read(adminTournamentsProvider.notifier)
                      .load(refresh: true),
                  children: [
                    for (final tournament in state.items) ...[
                      _TournamentCard(
                        tournament: tournament,
                        onStatusTap: () async {
                          final values = await showAdminActionDialog(
                            context: context,
                            title: 'Change tournament status',
                            message: 'Update status for ${tournament.name}.',
                            fields: const [
                              AdminActionField(
                                key: 'status',
                                label: 'Status',
                                options: _statuses,
                              ),
                            ],
                            confirmLabel: 'Update status',
                          );
                          if (values == null || !context.mounted) return;
                          await ref
                              .read(adminActionProvider.notifier)
                              .setTournamentStatus(
                                tournament.id,
                                values['status']!,
                              );
                        },
                        onDecision: (teamId, teamName) async {
                          final values = await showAdminActionDialog(
                            context: context,
                            title: 'Team decision',
                            message: 'Review $teamName for ${tournament.name}.',
                            fields: const [
                              AdminActionField(
                                key: 'decision',
                                label: 'Decision',
                                options: _decisions,
                              ),
                              AdminActionField(
                                key: 'reason',
                                label: 'Reason',
                                required: false,
                                maxLines: 3,
                              ),
                            ],
                            confirmLabel: 'Record decision',
                          );
                          if (values == null || !context.mounted) return;
                          await ref
                              .read(adminActionProvider.notifier)
                              .decideTournamentTeam(
                                tournament.id,
                                teamId,
                                values['decision']!,
                                reason: values['reason'],
                              );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () => ref
                            .read(adminTournamentsProvider.notifier)
                            .loadMore(),
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

class _TournamentCard extends ConsumerStatefulWidget {
  final AdminTournament tournament;
  final VoidCallback onStatusTap;
  final Future<void> Function(String teamId, String teamName) onDecision;

  const _TournamentCard({
    required this.tournament,
    required this.onStatusTap,
    required this.onDecision,
  });

  @override
  ConsumerState<_TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends ConsumerState<_TournamentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminTournamentDetailProvider(widget.tournament.id))
        : null;
    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(
            widget.tournament.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              widget.tournament.status,
              widget.tournament.format,
              '${widget.tournament.teamCount} teams',
            ].where((value) => value.isNotEmpty).join(' • '),
          ),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Organizer: ${widget.tournament.organizerName.isEmpty ? '-' : widget.tournament.organizerName}',
                  ),
                  Text('Matches: ${widget.tournament.matchCount}'),
                  if (detail != null)
                    detail.when(
                      data: (tournament) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final team in _teams(tournament)) ...[
                            Row(
                              children: [
                                Expanded(child: Text(team.$2)),
                                SizedBox(
                                  width: 110,
                                  child: AppButton.outlined(
                                    text: 'Decision',
                                    height: 34,
                                    onPressed: () =>
                                        widget.onDecision(team.$1, team.$2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (_teams(tournament).isEmpty)
                            const Text('No teams available to review.'),
                        ],
                      ),
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (error, _) => Text('Details unavailable: $error'),
                    ),
                  const SizedBox(height: 8),
                  AppButton.outlined(
                    text: 'Change status',
                    icon: Icons.toggle_off_outlined,
                    height: 38,
                    onPressed: widget.onStatusTap,
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

  List<(String, String)> _teams(AdminTournament tournament) {
    final teams = <(String, String)>[];
    for (final item in AdminJson.list(tournament.raw, const <String>[
      'teams',
      'participants',
      'requests',
      'registrations',
    ])) {
      final map = AdminJson.map(item);
      final nested = AdminJson.map(map['team']);
      final id = AdminJson.entityId(map);
      if (id.isEmpty) continue;
      final name = AdminJson.string(
        nested['name'] ?? map['name'] ?? map['teamName'],
        'Team $id',
      );
      teams.add((id, name));
    }
    return teams;
  }
}
