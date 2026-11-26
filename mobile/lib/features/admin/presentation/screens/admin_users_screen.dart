import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_user.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/admin_user_tile.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  static const List<String> _statuses = <String>[
    'ACTIVE',
    'PENDING',
    'BLOCKED',
    'SUSPENDED',
  ];
  static const List<String> _roles = <String>[
    'NORMAL_USER',
    'TEAM_OWNER',
    'PLAYER',
    'TOURNAMENT_ORGANIZER',
    'SCORER',
    'ADMIN',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersProvider);
    _listenToActions(context, ref);

    return AppScaffold(
      title: 'Admin Users',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminUsersProvider.notifier).load(refresh: true),
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
                statusLabel: 'Status',
                onSearchChanged: (value) =>
                    ref.read(adminUsersProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminUsersProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              _buildList(context, ref, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AdminListState<AdminUser> state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingWidget(message: 'Loading users...');
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(adminUsersProvider.notifier).load(refresh: true),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        title: 'No users found',
        subtitle: 'Adjust filters or refresh to load user accounts.',
        icon: Icons.people_outline,
      );
    }

    return AdminSectionCard(
      title: 'User accounts',
      subtitle: '${state.total} total',
      onRefresh: () =>
          ref.read(adminUsersProvider.notifier).load(refresh: true),
      children: [
        for (final user in state.items) ...[
          _tile(context, ref, user),
          const SizedBox(height: 8),
        ],
        if (state.hasNextPage)
          AppButton.outlined(
            text: state.isLoadingMore ? 'Loading...' : 'Load More',
            isLoading: state.isLoadingMore,
            height: 40,
            onPressed: () => ref.read(adminUsersProvider.notifier).loadMore(),
          ),
      ],
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AdminUser user) {
    return AdminUserTile(
      user: user,
      onStatusTap: () async {
        final values = await showAdminActionDialog(
          context: context,
          title: 'Change user status',
          message: 'Update the status for ${user.name}.',
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
            .setUserStatus(user.id, values['status']!);
      },
      onRoleTap: () async {
        final values = await showAdminActionDialog(
          context: context,
          title: 'Change user role',
          message: 'Assign a new role to ${user.name}.',
          warning: 'Role changes are visible to the backend and may affect permissions immediately.',
          fields: const [
            AdminActionField(key: 'role', label: 'Role', options: _roles),
          ],
          confirmLabel: 'Update role',
        );
        if (values == null || !context.mounted) return;
        await ref
            .read(adminActionProvider.notifier)
            .setUserRole(user.id, values['role']!);
      },
    );
  }

  void _listenToActions(BuildContext context, WidgetRef ref) {
    ref.listen<AdminActionState>(adminActionProvider, (previous, next) {
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });
  }
}
