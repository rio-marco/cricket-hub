import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_match.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminMatchesScreen extends ConsumerWidget {
  const AdminMatchesScreen({super.key});

  static const List<String> _statuses = <String>[
    'SCHEDULED',
    'LIVE',
    'COMPLETED',
    'ABANDONED',
    'CANCELLED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminMatchesProvider);
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
      title: 'Admin Matches',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminMatchesProvider.notifier).load(refresh: true),
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
                    ref.read(adminMatchesProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminMatchesProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading matches...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminMatchesProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No matches found',
                  icon: Icons.scoreboard_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Matches',
                  subtitle: '${state.total} total',
                  onRefresh: () => ref
                      .read(adminMatchesProvider.notifier)
                      .load(refresh: true),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Score corrections require an explicit reason. Corrections are audited.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final match in state.items) ...[
                      _MatchCard(
                        match: match,
                        onStatusTap: () async {
                          final values = await showAdminActionDialog(
                            context: context,
                            title: 'Change match status',
                            message:
                                'Update status for ${match.teamAName} vs ${match.teamBName}.',
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
                              .setMatchStatus(match.id, values['status']!);
                        },
                        onCorrect: () async {
                          final values = await showAdminActionDialog(
                            context: context,
                            title: 'Correct match score',
                            message:
                                'Submit a correction for ${match.teamAName} vs ${match.teamBName}.',
                            warning: 'Corrections are audited. Provide an explicit reason for every change.',
                            confirmLabel: 'Submit correction',
                            destructive: true,
                            fields: const [
                              AdminActionField(
                                key: 'reason',
                                label: 'Reason',
                                maxLines: 3,
                              ),
                              AdminActionField(
                                key: 'runs',
                                label: 'Runs',
                                keyboardType: TextInputType.number,
                                required: false,
                              ),
                              AdminActionField(
                                key: 'wickets',
                                label: 'Wickets',
                                keyboardType: TextInputType.number,
                                required: false,
                              ),
                              AdminActionField(
                                key: 'overs',
                                label: 'Overs',
                                keyboardType: TextInputType.number,
                                required: false,
                              ),
                              AdminActionField(
                                key: 'result',
                                label: 'Result',
                                required: false,
                              ),
                            ],
                          );
                          if (values == null || !context.mounted) return;
                          await ref
                              .read(adminActionProvider.notifier)
                              .correctMatch(
                                match.id,
                                reason: values['reason'] ?? '',
                                corrections: _corrections(values),
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
                        onPressed: () =>
                            ref.read(adminMatchesProvider.notifier).loadMore(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _corrections(Map<String, String> values) {
    final result = <String, dynamic>{};
    final runs = int.tryParse(values['runs'] ?? '');
    final wickets = int.tryParse(values['wickets'] ?? '');
    final overs = double.tryParse(values['overs'] ?? '');
    if (runs != null) result['runs'] = runs;
    if (wickets != null) result['wickets'] = wickets;
    if (overs != null) result['overs'] = overs;
    final summary = values['result'] ?? '';
    if (summary.isNotEmpty) result['result'] = summary;
    return result;
  }
}

class _MatchCard extends ConsumerStatefulWidget {
  final AdminMatch match;
  final VoidCallback onStatusTap;
  final VoidCallback onCorrect;

  const _MatchCard({
    required this.match,
    required this.onStatusTap,
    required this.onCorrect,
  });

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminMatchDetailProvider(widget.match.id))
        : null;
    final scorecard = _expanded
        ? ref.watch(adminMatchScorecardProvider(widget.match.id))
        : null;
    final events = _expanded
        ? ref.watch(adminMatchEventsProvider(widget.match.id))
        : null;
    final start = widget.match.startTime == null
        ? ''
        : DateFormat.yMMMd().add_jm().format(widget.match.startTime!.toLocal());

    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(
            '${widget.match.teamAName} vs ${widget.match.teamBName}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              widget.match.status,
              widget.match.format,
              widget.match.venue,
              start,
            ].where((value) => value.isNotEmpty).join(' • '),
          ),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.match.scoreSummary.isNotEmpty)
                    Text(widget.match.scoreSummary),
                  if (detail != null)
                    detail.when(
                      data: (match) => Text('Details: ${match.raw}'),
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (error, _) => Text('Details unavailable: $error'),
                    ),
                  if (scorecard != null)
                    _section(
                      'Scorecard',
                      scorecard.when(
                        data: (data) => Text(data.toString()),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            Text('Scorecard unavailable: $error'),
                      ),
                    ),
                  if (events != null)
                    _section(
                      'Events',
                      events.when(
                        data: (items) => items.isEmpty
                            ? const Text('No events recorded.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final event in items)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(event.toString()),
                                    ),
                                ],
                              ),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) => Text('Events unavailable: $error'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outlined(
                          text: 'Status',
                          icon: Icons.toggle_off_outlined,
                          height: 38,
                          onPressed: widget.onStatusTap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Correct',
                          icon: Icons.edit_note_outlined,
                          height: 38,
                          customColor: AppColors.error,
                          onPressed: widget.onCorrect,
                        ),
                      ),
                    ],
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

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
