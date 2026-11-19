import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';
import '../widgets/stats_card.dart';

/// Player Profile Screen with deep-dive batting, bowling, fielding metrics and history.
class PlayerDetailScreen extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
  });

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen>
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final playerState = ref.watch(playerDetailProvider(widget.playerId));

    if (playerState is PlayerDetailLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(elevation: 0),
        body: const LoadingWidget(message: 'Loading player career stats...'),
      );
    } else if (playerState is PlayerDetailError) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(elevation: 0),
        body: AppErrorWidget(
          message: playerState.message,
          onRetry: () => ref
              .read(playerDetailProvider(widget.playerId).notifier)
              .loadPlayerDetail(),
        ),
      );
    } else if (playerState is PlayerDetailLoaded) {
      final player = playerState.player;
      final matchHistory = playerState.matchHistory;

      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 310,
                pinned: true,
                stretch: true,
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Header Background
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

                      // Player Info Content
                      Positioned(
                        top: 80,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            // Avatar
                            _buildAvatar(player),
                            const SizedBox(height: 12),

                            // Name & Jersey
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (player.jerseyNumber != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${player.jerseyNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Role & Style info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    player.roleDisplay,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (player.city != null &&
                                    player.city!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${player.city}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              '${player.battingStyleDisplay}  |  ${player.bowlingStyleDisplay}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Batting'),
                      Tab(text: 'Bowling'),
                      Tab(text: 'Fielding'),
                      Tab(text: 'Matches'),
                    ],
                  ),
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: BATTING
              _buildBattingTab(player, isDark),

              // TAB 2: BOWLING
              _buildBowlingTab(player, isDark),

              // TAB 3: FIELDING
              _buildFieldingTab(player, isDark),

              // TAB 4: MATCHES
              _buildMatchesTab(matchHistory, isDark),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAvatar(Player player) {
    if (player.avatar != null && player.avatar!.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(player.avatar!),
          backgroundColor: Colors.grey.shade300,
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryLinearGradient,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        player.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBattingTab(Player player, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (player.bio != null && player.bio!.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              player.bio!,
              style: isDark
                  ? AppTextStyles.bodyMediumDark
                  : AppTextStyles.bodyMediumLight,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Batting Key Stats Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            StatsCard(
              label: 'Total Runs',
              value: '${player.runs}',
              icon: Icons.sports_cricket,
              hasGradient: true,
            ),
            StatsCard(
              label: 'Batting Average',
              value: player.battingAverage > 0
                  ? player.battingAverage.toStringAsFixed(1)
                  : '-',
              icon: Icons.analytics_outlined,
              iconColor: AppColors.boundaryFour,
            ),
            StatsCard(
              label: 'Strike Rate',
              value: player.strikeRate > 0
                  ? player.strikeRate.toStringAsFixed(1)
                  : '-',
              icon: Icons.speed_rounded,
              iconColor: AppColors.warning,
            ),
            StatsCard(
              label: 'Highest Score',
              value: '${player.highestScore}',
              icon: Icons.emoji_events_outlined,
              iconColor: AppColors.trophyGold,
            ),
            StatsCard(
              label: 'Innings / Matches',
              value: '${player.matchesCount}',
              icon: Icons.scoreboard_outlined,
              iconColor: AppColors.info,
            ),
            StatsCard(
              label: 'Balls Faced',
              value: '${player.ballsFaced}',
              icon: Icons.circle_outlined,
              iconColor: AppColors.secondaryLight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlingTab(Player player, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            StatsCard(
              label: 'Wickets Taken',
              value: '${player.wickets}',
              icon: Icons.sports_baseball,
              hasGradient: true,
              customGradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            StatsCard(
              label: 'Economy Rate',
              value: player.economyRate > 0
                  ? player.economyRate.toStringAsFixed(2)
                  : '-',
              icon: Icons.trending_down_rounded,
              iconColor: AppColors.pitchGreen,
            ),
            StatsCard(
              label: 'Overs Bowled',
              value: '${player.oversBowled}',
              icon: Icons.replay_outlined,
              iconColor: AppColors.info,
            ),
            StatsCard(
              label: 'Runs Conceded',
              value: '${player.runsConceded}',
              icon: Icons.remove_circle_outline,
              iconColor: AppColors.error,
            ),
            StatsCard(
              label: 'Best Bowling',
              value: player.bestBowling ?? '-',
              icon: Icons.military_tech_outlined,
              iconColor: AppColors.warning,
            ),
            StatsCard(
              label: 'Bowling Avg',
              value: player.bowlingAverage > 0
                  ? player.bowlingAverage.toStringAsFixed(1)
                  : '-',
              icon: Icons.equalizer_rounded,
              iconColor: AppColors.secondaryLight,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldingTab(Player player, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            StatsCard(
              label: 'Catches Taken',
              value: '${player.catches}',
              icon: Icons.front_hand_outlined,
              iconColor: AppColors.info,
            ),
            StatsCard(
              label: 'Stumpings',
              value: '${player.stumpings}',
              icon: Icons.sports_baseball_outlined,
              iconColor: AppColors.boundarySix,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchesTab(List<dynamic> matches, bool isDark) {
    if (matches.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Matches Recorded',
        subtitle:
            'Match performances and scorecards will show up here once this player competes.',
        icon: Icons.sports_cricket_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final matchTitle = match is Map ? match['title'] ?? 'Cricket Match' : 'Match';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_cricket, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  matchTitle.toString(),
                  style: isDark
                      ? AppTextStyles.bodyMediumDark
                      : AppTextStyles.bodyMediumLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverAppBarDelegate(this._tabBar, this._bgColor);

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
      color: _bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
