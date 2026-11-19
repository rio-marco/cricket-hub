import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/widgets/team_card.dart';
import '../../domain/entities/dashboard_data.dart';
import '../providers/dashboard_provider.dart';

/// Primary Landing Hub showcasing live cricket action, quick tournaments overview,
/// team rosters, and rapid actions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = ref.watch(currentUserProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(dashboardProvider.notifier)
                .loadDashboard(isRefresh: true);
          },
          color: AppColors.primary,
          child: switch (dashboardState) {
            DashboardLoading() => const LoadingWidget(
                message: 'Preparing your cricket feed...',
              ),
            DashboardError(message: final msg) => AppErrorWidget(
                message: msg,
                onRetry: () => ref
                    .read(dashboardProvider.notifier)
                    .loadDashboard(isRefresh: true),
              ),
            DashboardLoaded(data: final data) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. WELCOME HEADER WITH USER INFO
                    _buildWelcomeHeader(context, user, isDark),
                    const SizedBox(height: 16),

                    // 2. QUICK STATS ROW
                    _buildStatsRow(data, isDark),
                    const SizedBox(height: 24),

                    // 3. QUICK ACTIONS GRID
                    _buildQuickActions(context, isDark),
                    const SizedBox(height: 24),

                    // 4. LIVE MATCHES SECTION
                    if (data.liveMatches.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Live Matches',
                        badge: '${data.liveMatches.length} LIVE',
                        badgeColor: AppColors.liveRed,
                        onSeeAll: () => context.go(AppRoutes.matches),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildLiveMatchesCarousel(
                        context,
                        data.liveMatches,
                        isDark,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 5. MY TEAMS CAROUSEL
                    if (data.myTeams.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'My Teams',
                        onSeeAll: () => context.go(AppRoutes.teams),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildMyTeamsList(context, data.myTeams),
                      const SizedBox(height: 24),
                    ],

                    // 6. UPCOMING MATCHES
                    if (data.upcomingMatches.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Upcoming Matches',
                        onSeeAll: () => context.go(AppRoutes.matches),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildUpcomingList(context, data.upcomingMatches, isDark),
                      const SizedBox(height: 24),
                    ],

                    // 7. RECENT RESULTS
                    if (data.recentResults.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        title: 'Recent Results',
                        onSeeAll: () => context.go(AppRoutes.matches),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildResultsList(context, data.recentResults, isDark),
                    ],
                  ],
                ),
              ),
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. WELCOME HEADER
  // ===========================================================================
  Widget _buildWelcomeHeader(BuildContext context, dynamic user, bool isDark) {
    final name = user?.name ?? 'Cricket Fan';
    final avatar = user?.avatar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go(AppRoutes.profile),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryLinearGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: avatar != null && avatar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(avatar, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            user?.initials ?? 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: (isDark
                            ? AppTextStyles.bodySmallDark
                            : AppTextStyles.bodySmallLight)
                        .copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: (isDark
                            ? AppTextStyles.titleLargeDark
                            : AppTextStyles.titleLargeLight)
                        .copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Notification icon button
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F2F5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              onPressed: () => context.push(AppRoutes.notifications),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. QUICK STATS ROW
  // ===========================================================================
  Widget _buildStatsRow(DashboardData data, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildGradientStatTile(
              label: 'Matches',
              value: '${data.totalMatches}',
              icon: Icons.sports_cricket_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildGradientStatTile(
              label: 'Teams',
              value: '${data.totalTeams}',
              icon: Icons.groups_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2838), Color(0xFF2C3E50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildGradientStatTile(
              label: 'Tournaments',
              value: '${data.totalTournaments}',
              icon: Icons.emoji_events_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFFAB40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientStatTile({
    required String label,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. QUICK ACTIONS GRID
  // ===========================================================================
  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: (isDark
                    ? AppTextStyles.titleMediumDark
                    : AppTextStyles.titleMediumLight)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.group_add_rounded,
                  label: 'Create Team',
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.createTeam),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.sports_cricket,
                  label: 'Start Match',
                  color: const Color(0xFF1E88E5),
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.createMatch),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Tournament',
                  color: const Color(0xFF8E24AA),
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.createTournament),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.badge_outlined,
                  label: 'Players',
                  color: AppColors.pitchGreen,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.players),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: (isDark
                        ? AppTextStyles.labelSmallDark
                        : AppTextStyles.labelSmallLight)
                    .copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. LIVE MATCHES CAROUSEL
  // ===========================================================================
  Widget _buildLiveMatchesCarousel(
    BuildContext context,
    List<DashboardMatch> matches,
    bool isDark,
  ) {
    return SizedBox(
      height: 184,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return Container(
            width: 310,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.liveRed.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.liveRed.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/matches/${match.id}'),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row: Tournament & LIVE Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              match.tournamentName ?? 'Live Match',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.liveRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 6, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Teams and Scores
                      Column(
                        children: [
                          _buildMatchTeamScoreRow(
                            name: match.teamAName,
                            runs: match.teamARuns,
                            wickets: match.teamAWickets,
                            overs: match.teamAOvers,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildMatchTeamScoreRow(
                            name: match.teamBName,
                            runs: match.teamBRuns,
                            wickets: match.teamBWickets,
                            overs: match.teamBOvers,
                            isDark: isDark,
                          ),
                        ],
                      ),

                      // Status Text Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchTeamScoreRow({
    required String name,
    required int runs,
    required int wickets,
    required double overs,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0] : 'T',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: (isDark
                      ? AppTextStyles.titleSmallDark
                      : AppTextStyles.titleSmallLight)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Text(
          '$runs/$wickets ($overs ov)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. MY TEAMS HORIZONTAL LIST
  // ===========================================================================
  Widget _buildMyTeamsList(BuildContext context, List<Team> teams) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return TeamCard(
            team: team,
            isCompact: true,
            onTap: () => context.push('/teams/${team.id}'),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 6. UPCOMING MATCHES LIST
  // ===========================================================================
  Widget _buildUpcomingList(
    BuildContext context,
    List<DashboardMatch> matches,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Calendar Date Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      match.format,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Match Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.teamAName} vs ${match.teamBName}',
                      style: (isDark
                              ? AppTextStyles.titleSmallDark
                              : AppTextStyles.titleSmallLight)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textDisabledDark
                    : AppColors.textDisabledLight,
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 7. RECENT RESULTS LIST
  // ===========================================================================
  Widget _buildResultsList(
    BuildContext context,
    List<DashboardMatch> matches,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.tournamentName ?? 'Completed Match',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'COMPLETED',
                      style: AppTextStyles.labelSmallLight.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.teamAName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${match.teamARuns}/${match.teamAWickets} (${match.teamAOvers})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.teamBName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${match.teamBRuns}/${match.teamBWickets} (${match.teamBOvers})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                match.statusText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION HEADER HELPER
  // ===========================================================================
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? badge,
    Color? badgeColor,
    required VoidCallback onSeeAll,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: (isDark
                        ? AppTextStyles.titleMediumDark
                        : AppTextStyles.titleMediumLight)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primary).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor ?? AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }
}
