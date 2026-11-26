import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);

    return AppScaffold(
      title: 'Admin Dashboard',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminDashboardProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildContent(context, ref, state),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    if (state.isLoading && state.stats == null) {
      return const LoadingWidget(message: 'Loading admin dashboard...');
    }
    if (state.errorMessage != null && state.stats == null) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(adminDashboardProvider.notifier).load(refresh: true),
      );
    }
    final stats = state.stats;
    if (stats == null || stats.metrics.isEmpty) {
      return const EmptyStateWidget(
        title: 'No dashboard data',
        subtitle: 'The admin dashboard has no metrics available yet.',
        icon: Icons.dashboard_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            AdminStatCard(
              label: 'Users',
              value: '${stats.totalUsers}',
              icon: Icons.people_outline,
            ),
            AdminStatCard(
              label: 'Teams',
              value: '${stats.totalTeams}',
              icon: Icons.groups_outlined,
              color: AppColors.info,
            ),
            AdminStatCard(
              label: 'Players',
              value: '${stats.totalPlayers}',
              icon: Icons.sports_cricket_outlined,
              color: AppColors.pitchGreen,
            ),
            AdminStatCard(
              label: 'Tournaments',
              value: '${stats.totalTournaments}',
              icon: Icons.emoji_events_outlined,
              color: AppColors.trophyGold,
            ),
            AdminStatCard(
              label: 'Matches',
              value: '${stats.totalMatches}',
              icon: Icons.scoreboard_outlined,
              color: AppColors.accent,
            ),
            AdminStatCard(
              label: 'Live Matches',
              value: '${stats.liveMatches}',
              icon: Icons.live_tv_outlined,
              color: AppColors.liveRed,
            ),
            AdminStatCard(
              label: 'Active Auctions',
              value: '${stats.activeAuctions}',
              icon: Icons.gavel_outlined,
              color: AppColors.secondaryLight,
            ),
            AdminStatCard(
              label: 'Reports',
              value: '${stats.totalReports}',
              icon: Icons.report_problem_outlined,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Quick access',
          subtitle: 'Administrative sections',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickButton(context, 'Users', AppRoutes.adminUsers),
                _quickButton(context, 'Matches', AppRoutes.adminMatches),
                _quickButton(context, 'Auctions', AppRoutes.adminAuctions),
                _quickButton(context, 'Audits', AppRoutes.adminAudits),
              ],
            ),
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _quickButton(BuildContext context, String label, String route) {
    return SizedBox(
      width: 170,
      child: AppButton.outlined(
        text: label,
        height: 38,
        onPressed: () => context.go(route),
      ),
    );
  }
}
