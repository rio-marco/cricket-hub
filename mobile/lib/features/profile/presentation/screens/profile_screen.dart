import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../../../teams/presentation/widgets/team_card.dart';

/// User Account and Cricket Profile Hub featuring personal records, squad memberships,
/// and preferences.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of Cricket Hub?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'v${AppConstants.appVersion}',
      applicationLegalese: '© 2026 Cricket Hub. All rights reserved.',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryLinearGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.sports_cricket,
          color: Colors.white,
          size: 28,
        ),
      ),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Cricket Hub is the premier live cricket scoring, tournament management, player auction, and cricket analytics platform.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final playerProfileAsync = ref.watch(myPlayerProfileProvider);
    final myTeamsState = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. GRADIENT HEADER BANNER WITH USER PROFILE
            _buildProfileHeader(context, user, isDark),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. MY PLAYER PROFILE CARD
                  _buildPlayerProfileCard(
                    context,
                    playerProfileAsync,
                    isDark,
                  ),
                  const SizedBox(height: 20),

                  // 3. MY TEAMS SECTION
                  _buildMyTeamsSection(context, myTeamsState, isDark),
                  const SizedBox(height: 20),

                  // 4. ACCOUNT & SETTINGS LIST
                  _buildSettingsSection(context, ref, isDark, isAdmin),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 54, bottom: 28, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F1722),
            Color(0xFF1B2838),
            Color(0xFF2C3E50),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Avatar & Name
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryLinearGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: user?.avatar != null && user.avatar.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(user.avatar, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      user?.initials ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'Cricket Player',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Text(
              user?.role.toUpperCase() ?? 'PLAYER',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfileCard(
    BuildContext context,
    AsyncValue<dynamic> playerProfileAsync,
    bool isDark,
  ) {
    return playerProfileAsync.when(
      data: (player) {
        if (player != null) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryLinearGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/players/${player.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_cricket,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Player Profile Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${player.roleDisplay} • ${player.battingStyleDisplay}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // No player profile yet
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register as a Player',
                      style: (isDark
                              ? AppTextStyles.titleSmallDark
                              : AppTextStyles.titleSmallLight)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Record career runs, wickets, and enter player auctions.',
                      style: (isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmallLight)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => context.push('/players/create'),
                child: const Text('Register', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMyTeamsSection(
    BuildContext context,
    TeamListState myTeamsState,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Teams',
              style: (isDark
                      ? AppTextStyles.titleMediumDark
                      : AppTextStyles.titleMediumLight)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.createTeam),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Team'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (myTeamsState is TeamListLoaded && myTeamsState.teams.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: myTeamsState.teams.length,
              itemBuilder: (context, index) {
                final team = myTeamsState.teams[index];
                return TeamCard(
                  team: team,
                  isCompact: true,
                  onTap: () => context.push('/teams/${team.id}'),
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "You haven't joined or created a squad yet.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.createTeam),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account & Preferences',
          style: (isDark
                  ? AppTextStyles.titleMediumDark
                  : AppTextStyles.titleMediumLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (isAdmin) ...[
                _buildSettingTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin Console',
                  subtitle: 'Manage users, competitions and audit trails',
                  isDark: isDark,
                  onTap: () => context.go(AppRoutes.adminShell),
                ),
                _buildDivider(isDark),
              ],
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Match alerts, team invites & score updates',
                isDark: isDark,
                onTap: () => context.push(AppRoutes.notifications),
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.tune_rounded,
                title: 'App Settings & Themes',
                subtitle: 'Dark mode, scoring presets, server URL',
                isDark: isDark,
                onTap: () => context.push(AppRoutes.settings),
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About Cricket Hub',
                subtitle: 'Version ${AppConstants.appVersion}',
                isDark: isDark,
                onTap: () => _showAboutDialog(context),
              ),
              _buildDivider(isDark),
              _buildSettingTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Log out of your account on this device',
                iconColor: AppColors.error,
                titleColor: AppColors.error,
                isDark: isDark,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: titleColor ??
              (isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark
            ? AppColors.textDisabledDark
            : AppColors.textDisabledLight,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 56,
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    );
  }
}
