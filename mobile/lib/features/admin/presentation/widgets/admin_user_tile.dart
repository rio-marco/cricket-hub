import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/admin_user.dart';
import '../providers/admin_provider.dart';

class AdminUserTile extends ConsumerStatefulWidget {
  final AdminUser user;
  final VoidCallback onStatusTap;
  final VoidCallback onRoleTap;

  const AdminUserTile({
    super.key,
    required this.user,
    required this.onStatusTap,
    required this.onRoleTap,
  });

  @override
  ConsumerState<AdminUserTile> createState() => _AdminUserTileState();
}

class _AdminUserTileState extends ConsumerState<AdminUserTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminUserDetailProvider(widget.user.id))
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            key: ValueKey<String>('admin-user-${widget.user.id}'),
            initiallyExpanded: false,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.16),
              child: Text(
                widget.user.name.isEmpty
                    ? '?'
                    : widget.user.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: Text(
              widget.user.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(widget.user.email),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.user.isBlocked
                    ? AppColors.error.withOpacity(0.12)
                    : AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.user.statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.user.isBlocked
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _info('Role', widget.user.role),
                    _info('Verified', widget.user.isVerified ? 'Yes' : 'No'),
                    _info('Teams', '${widget.user.teamCount}'),
                    if (widget.user.phone != null)
                      _info('Phone', widget.user.phone!),
                    if (detail != null) ...[
                      const SizedBox(height: 8),
                      detail.when(
                        data: (value) => _info('Details', value.raw.toString()),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) => Text(
                          'Details unavailable: $error',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            text: 'Status',
                            icon: Icons.lock_outline,
                            height: 38,
                            onPressed: widget.onStatusTap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton.outlined(
                            text: 'Role',
                            icon: Icons.manage_accounts_outlined,
                            height: 38,
                            onPressed: widget.onRoleTap,
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
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
