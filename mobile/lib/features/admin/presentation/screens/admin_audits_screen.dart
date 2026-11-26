import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_audit_log.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/audit_log_tile.dart';

class AdminAuditsScreen extends ConsumerStatefulWidget {
  const AdminAuditsScreen({super.key});

  @override
  ConsumerState<AdminAuditsScreen> createState() => _AdminAuditsScreenState();
}

class _AdminAuditsScreenState extends ConsumerState<AdminAuditsScreen> {
  int _category = 0;

  static const List<String> _categories = <String>['All', 'Scoring', 'Auction'];

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminAuditsProvider);
    final scoring = ref.watch(adminScoringAuditsProvider);
    final auction = ref.watch(adminAuctionAuditsProvider);
    final state = switch (_category) {
      1 => scoring,
      2 => auction,
      _ => all,
    };

    return AppScaffold(
      title: 'Admin Audits',
      body: RefreshIndicator(
        onRefresh: () => _notifier.load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 0, label: Text('All')),
                  ButtonSegment<int>(value: 1, label: Text('Scoring')),
                  ButtonSegment<int>(value: 2, label: Text('Auction')),
                ],
                selected: <int>{_category},
                onSelectionChanged: (values) =>
                    setState(() => _category = values.first),
              ),
              const SizedBox(height: 16),
              AdminFilterBar(
                search: state.search,
                status: '',
                statusLabel: 'Category',
                onSearchChanged: (value) => _notifier.setSearch(value),
                onStatusChanged: (_) {},
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading audit logs...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => _notifier.load(refresh: true),
                )
              else if (state.items.isEmpty)
                EmptyStateWidget(
                  title:
                      'No ${_categories[_category].toLowerCase()} audits found',
                  icon: Icons.history_rounded,
                )
              else
                AdminSectionCard(
                  title: '${_categories[_category]} audit log',
                  subtitle: '${state.total} total',
                  onRefresh: () => _notifier.load(refresh: true),
                  children: [
                    for (final entry in state.items) ...[
                      AuditLogTile(entry: entry),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () => _notifier.loadMore(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  AdminListNotifier<AdminAuditLog> get _notifier {
    return switch (_category) {
      1 => ref.read(adminScoringAuditsProvider.notifier),
      2 => ref.read(adminAuctionAuditsProvider.notifier),
      _ => ref.read(adminAuditsProvider.notifier),
    };
  }
}
