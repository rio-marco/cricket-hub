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
import '../providers/admin_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  static const List<String> _statuses = <String>[
    'OPEN',
    'REVIEWING',
    'RESOLVED',
    'DISMISSED',
  ];
  static const List<String> _formats = <String>['json', 'csv'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportsProvider);
    final action = ref.watch(adminActionProvider);
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
      title: 'Admin Reports',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminReportsProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionCard(
                title: 'Export reports',
                subtitle: 'Download a backend-generated export',
                children: [
                  AppButton.outlined(
                    text: 'Export',
                    icon: Icons.file_download_outlined,
                    isLoading: action.isSaving,
                    height: 42,
                    onPressed: () async {
                      final values = await showAdminActionDialog(
                        context: context,
                        title: 'Export reports',
                        message: 'Choose the export format and optional status filter.',
                        confirmLabel: 'Export',
                        fields: const [
                          AdminActionField(
                            key: 'format',
                            label: 'Format',
                            options: _formats,
                          ),
                          AdminActionField(
                            key: 'status',
                            label: 'Status',
                            options: _statuses,
                            required: false,
                          ),
                        ],
                      );
                      if (values == null || !context.mounted) return;
                      await ref
                          .read(adminActionProvider.notifier)
                          .exportReports(
                            format: values['format'],
                            status: values['status'],
                          );
                    },
                  ),
                  if (action.lastResult != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Export result: ${action.lastResult}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AdminFilterBar(
                search: state.search,
                status: state.status,
                statuses: _statuses,
                onSearchChanged: (value) =>
                    ref.read(adminReportsProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminReportsProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading reports...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminReportsProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No reports found',
                  icon: Icons.report_problem_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Reports',
                  subtitle: '${state.total} total',
                  onRefresh: () => ref
                      .read(adminReportsProvider.notifier)
                      .load(refresh: true),
                  children: [
                    for (final report in state.items) ...[
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    report.type,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(report.status.toUpperCase()),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (report.reason.isNotEmpty) Text(report.reason),
                            Text(
                              [
                                if (report.reporterName.isNotEmpty)
                                  'By ${report.reporterName}',
                                if (report.targetLabel.isNotEmpty)
                                  report.targetLabel,
                              ].join(' • '),
                            ),
                            if (report.createdAt != null)
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  report.createdAt!.toLocal(),
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () =>
                            ref.read(adminReportsProvider.notifier).loadMore(),
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
