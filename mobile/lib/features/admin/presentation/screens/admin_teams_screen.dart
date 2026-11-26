import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_team.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminTeamsScreen extends ConsumerWidget {
  const AdminTeamsScreen({super.key});

  static const List<String> _statuses = <String>[
    'ACTIVE',
    'INACTIVE',
    'SUSPENDED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminTeamsProvider);
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
      title: 'Admin Teams',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminTeamsProvider.notifier).load(refresh: true),
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
                onSearchChanged: (value) =>
                    ref.read(adminTeamsProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminTeamsProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading teams...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(adminTeamsProvider.notifier).load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No teams found',
                  icon: Icons.groups_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Teams',
                  subtitle: '${state.total} total',
                  onRefresh: () =>
                      ref.read(adminTeamsProvider.notifier).load(refresh: true),
                  children: [
                    for (final team in state.items) ...[
                      _TeamCard(
                        team: team,
                        onStatusTap: () async {
                          final values = await showAdminActionDialog(
                            context: context,
                            title: 'Change team status',
                            message: 'Update status for ${team.name}.',
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
                              .setTeamStatus(team.id, values['status']!);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () =>
                            ref.read(adminTeamsProvider.notifier).loadMore(),
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

class _TeamCard extends ConsumerStatefulWidget {
  final AdminTeam team;
  final VoidCallback onStatusTap;

  const _TeamCard({required this.team, required this.onStatusTap});

  @override
  ConsumerState<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends ConsumerState<_TeamCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminTeamDetailProvider(widget.team.id))
        : null;
    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(
            widget.team.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              widget.team.shortName,
              widget.team.tournamentName,
              widget.team.status,
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
                    'Owner: ${widget.team.ownerName.isEmpty ? '-' : widget.team.ownerName}',
                  ),
                  Text('Members: ${widget.team.memberCount}'),
                  if (detail != null)
                    detail.when(
                      data: (team) => Text('Details: ${team.raw}'),
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
}
