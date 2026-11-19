import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_team.dart';
import '../providers/tournament_provider.dart';
import '../widgets/fixture_card.dart';
import '../widgets/points_table.dart';

/// Comprehensive tournament detail screen showcasing hero banner, quick facts,
/// and tabbed views for registered Teams, Fixtures schedule, Standings, and Stats.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRegisterTeamDialog(BuildContext context, Tournament tournament) {
    final teamNameController = TextEditingController();
    final teamShortNameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollable: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group_add_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Your Team',
                            style: (isDark
                                    ? AppTextStyles.titleMediumDark
                                    : AppTextStyles.titleMediumLight)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            tournament.name,
                            style: (isDark
                                    ? AppTextStyles.bodySmallDark
                                    : AppTextStyles.bodySmallLight)
                                .copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: teamNameController,
                  decoration: InputDecoration(
                    labelText: 'Team Name *',
                    hintText: 'e.g. Royal Challengers Mumbai',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.shield_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: teamShortNameController,
                  decoration: InputDecoration(
                    labelText: 'Short Name / Code *',
                    hintText: 'e.g. RCM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Entry Registration Fee:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        tournament.registrationFee > 0
                            ? '₹${tournament.registrationFee.toInt()}'
                            : 'FREE ENTRY',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                AppButton(
                  text: 'Submit Enrollment',
                  icon: Icons.check_circle_rounded,
                  onPressed: () async {
                    if (teamNameController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);

                    final teamId = 'team_${DateTime.now().millisecondsSinceEpoch}';
                    final success = await ref
                        .read(tournamentActionProvider.notifier)
                        .registerTeam(widget.tournamentId, teamId);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Team enrollment request submitted successfully!'
                                : 'Failed to register team.',
                          ),
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                        ),
                      );
                      ref.invalidate(tournamentTeamsProvider(widget.tournamentId));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateFixtures() async {
    final success = await ref
        .read(tournamentActionProvider.notifier)
        .generateFixtures(widget.tournamentId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Match schedule fixtures generated successfully!'
                : 'Failed to generate fixtures.',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      ref.invalidate(tournamentFixturesProvider(widget.tournamentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tournamentAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: tournamentAsync.when(
        loading: () => const LoadingWidget(message: 'Loading tournament details...'),
        error: (err, stack) => AppErrorWidget(
          title: 'Tournament Not Found',
          message: err.toString(),
          onRetry: () => ref.invalidate(tournamentDetailProvider(widget.tournamentId)),
        ),
        data: (tournament) => _buildDetailScaffold(context, tournament, isDark),
      ),
    );
  }

  Widget _buildDetailScaffold(
    BuildContext context,
    Tournament tournament,
    bool isDark,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Collapsible Hero Banner App Bar
          _buildSliverAppBar(context, tournament, isDark),

          // Quick Info Stat Cards
          SliverToBoxAdapter(
            child: _buildQuickFactsCard(tournament, isDark),
          ),

          // Sticky Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Teams'),
                  Tab(text: 'Fixtures'),
                  Tab(text: 'Standings'),
                  Tab(text: 'Info & Rules'),
                ],
              ),
              isDark: isDark,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Teams
          _buildTeamsTab(tournament, isDark),

          // Tab 2: Fixtures
          _buildFixturesTab(tournament, isDark),

          // Tab 3: Standings
          _buildStandingsTab(tournament, isDark),

          // Tab 4: Info & Rules
          _buildRulesTab(tournament, isDark),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    Tournament tournament,
    bool isDark,
  ) {
    final statusColor = tournament.statusColor;

    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tournament link copied to clipboard!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Dark Gradient Header
            Container(
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
              ),
            ),

            // Background Trophy watermark
            Positioned(
              right: -10,
              bottom: 10,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 160,
                color: Colors.white.withOpacity(0.06),
              ),
            ),

            // Gradient Overlay at bottom
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Title & Status Badge at bottom of flexible space
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tournament.statusDisplayName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${tournament.matchFormat} • ${tournament.ballType} BALL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tournament.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFactsCard(Tournament tournament, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildFactItem(
                icon: Icons.calendar_today_rounded,
                label: 'Dates',
                val: tournament.dateRangeFormatted,
                isDark: isDark,
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              _buildFactItem(
                icon: Icons.location_on_rounded,
                label: 'City & Ground',
                val: tournament.city ?? 'Local Grounds',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFactItem(
                icon: Icons.groups_rounded,
                label: 'Cap & Teams',
                val: '${tournament.teamsCount} / ${tournament.maxTeams} Teams',
                isDark: isDark,
              ),
              Container(
                height: 36,
                width: 1,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
              _buildFactItem(
                icon: Icons.currency_rupee_rounded,
                label: 'Registration Fee',
                val: tournament.registrationFee > 0
                    ? '₹${tournament.registrationFee.toInt()} / team'
                    : 'Free Entry',
                isDark: isDark,
                valueColor: tournament.registrationFee > 0 ? null : AppColors.success,
              ),
            ],
          ),

          // Primary CTA Bar if registration open
          if (tournament.isRegistrationOpen) ...[
            const SizedBox(height: 16),
            AppButton(
              text: 'Register Your Team Now',
              icon: Icons.app_registration_rounded,
              onPressed: () => _showRegisterTeamDialog(context, tournament),
              height: 46,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactItem({
    required IconData icon,
    required String label,
    required String val,
    required bool isDark,
    Color? valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    val,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: valueColor ??
                          (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Teams
  // ---------------------------------------------------------------------------
  Widget _buildTeamsTab(Tournament tournament, bool isDark) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(widget.tournamentId));

    return teamsAsync.when(
      loading: () => const LoadingWidget(message: 'Loading enrolled teams...'),
      error: (e, s) => AppErrorWidget(
        title: 'Unable to Load Teams',
        message: e.toString(),
        onRetry: () => ref.invalidate(tournamentTeamsProvider(widget.tournamentId)),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.group_off_rounded,
            title: 'No Teams Enrolled Yet',
            subtitle: tournament.isRegistrationOpen
                ? 'Be the first team to enter the championship!'
                : 'Registration has not commenced yet.',
            actionText: tournament.isRegistrationOpen ? 'Register Team' : null,
            onActionPressed: tournament.isRegistrationOpen
                ? () => _showRegisterTeamDialog(context, tournament)
                : null,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participating Squads (${teams.length})',
                  style: (isDark ? AppTextStyles.titleSmallDark : AppTextStyles.titleSmallLight)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                if (tournament.isRegistrationOpen)
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Team'),
                    onPressed: () => _showRegisterTeamDialog(context, tournament),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            ...teams.map((t) => _buildTeamTile(t, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildTeamTile(TournamentTeam team, bool isDark) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                team.teamShortName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.teamName,
                  style: (isDark ? AppTextStyles.titleSmallDark : AppTextStyles.titleSmallLight)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Played: ${team.played} • Won: ${team.won} • Points: ${team.points}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              team.status,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Fixtures
  // ---------------------------------------------------------------------------
  Widget _buildFixturesTab(Tournament tournament, bool isDark) {
    final fixturesAsync = ref.watch(tournamentFixturesProvider(widget.tournamentId));

    return fixturesAsync.when(
      loading: () => const LoadingWidget(message: 'Loading fixtures schedule...'),
      error: (e, s) => AppErrorWidget(
        title: 'Unable to Load Fixtures',
        message: e.toString(),
        onRetry: () => ref.invalidate(tournamentFixturesProvider(widget.tournamentId)),
      ),
      data: (fixtures) {
        if (fixtures.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.calendar_month_outlined,
            title: 'No Matches Scheduled',
            subtitle: 'Fixtures have not been generated yet for this tournament.',
            actionText: 'Generate Fixtures',
            actionIcon: Icons.auto_awesome_rounded,
            onActionPressed: _generateFixtures,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Match Schedule (${fixtures.length})',
                  style: (isDark ? AppTextStyles.titleSmallDark : AppTextStyles.titleSmallLight)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate'),
                  onPressed: _generateFixtures,
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...fixtures.map((fix) {
              return FixtureCard(
                fixture: fix,
                onTap: () {
                  final matchId = fix['id']?.toString() ?? fix['_id']?.toString();
                  if (matchId != null) {
                    context.push('/matches/$matchId');
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Standings (Points Table)
  // ---------------------------------------------------------------------------
  Widget _buildStandingsTab(Tournament tournament, bool isDark) {
    final tableAsync = ref.watch(pointsTableProvider(widget.tournamentId));

    return tableAsync.when(
      loading: () => const LoadingWidget(message: 'Loading points table...'),
      error: (e, s) => AppErrorWidget(
        title: 'Unable to Load Standings',
        message: e.toString(),
        onRetry: () => ref.invalidate(pointsTableProvider(widget.tournamentId)),
      ),
      data: (teams) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Championship Standings',
                style: (isDark ? AppTextStyles.titleSmallDark : AppTextStyles.titleSmallLight)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              PointsTableWidget(
                teams: teams,
                playoffCutoff: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: Info & Rules
  // ---------------------------------------------------------------------------
  Widget _buildRulesTab(Tournament tournament, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organizer Info Card
          AppCard(
            headerTitle: 'Organized By',
            headerLeading: const Icon(Icons.verified_user_rounded, color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.organizerName,
                  style: (isDark ? AppTextStyles.titleSmallDark : AppTextStyles.titleSmallLight)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Official Tournament Host on Cricket Hub Platform.',
                  style: isDark ? AppTextStyles.bodySmallDark : AppTextStyles.bodySmallLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ground & Venues Card
          AppCard(
            headerTitle: 'Host Venues & Grounds',
            headerLeading: const Icon(Icons.stadium_rounded, color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tournament.venues.isNotEmpty
                  ? tournament.venues.map((v) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              v,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  : [
                      const Text(
                        'Venues will be confirmed prior to tournament commencement.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 16),

          // Rules & Regulations Card
          AppCard(
            headerTitle: 'Tournament Guidelines & Rules',
            headerLeading: const Icon(Icons.gavel_rounded, color: AppColors.primary),
            child: Text(
              tournament.rules ??
                  'Standard ICC Cricket Playing Conditions apply. Reporting time is 30 minutes before toss. Umpires decision is final. Super over in case of tied playoff match.',
              style: (isDark ? AppTextStyles.bodyMediumDark : AppTextStyles.bodyMediumLight)
                  .copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate keeping TabBar pinned on scroll
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this._tabBar, {required this.isDark});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
