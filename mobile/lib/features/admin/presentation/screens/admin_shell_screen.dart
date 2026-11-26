import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key});

  static const List<MapEntry<String, String>> sections = [
    MapEntry<String, String>('Dashboard', AppRoutes.adminDashboard),
    MapEntry<String, String>('Users', AppRoutes.adminUsers),
    MapEntry<String, String>('Teams', AppRoutes.adminTeams),
    MapEntry<String, String>('Players', AppRoutes.adminPlayers),
    MapEntry<String, String>('Tournaments', AppRoutes.adminTournaments),
    MapEntry<String, String>('Matches', AppRoutes.adminMatches),
    MapEntry<String, String>('Auctions', AppRoutes.adminAuctions),
    MapEntry<String, String>('Notifications', AppRoutes.adminNotifications),
    MapEntry<String, String>('Reports', AppRoutes.adminReports),
    MapEntry<String, String>('Audits', AppRoutes.adminAudits),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: 'Admin Console',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              hasGradientHeader: true,
              headerTitle: 'Administration',
              headerSubtitle: 'Backend-authoritative controls',
              child: Text(
                'Manage users, competitions, scoring corrections, notifications and audit trails.',
                style: isDark
                    ? const TextStyle(color: AppColors.textPrimaryDark)
                    : const TextStyle(color: AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 16),
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.go(section.value),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
