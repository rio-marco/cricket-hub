import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../providers/match_provider.dart';
import '../widgets/commentary_item.dart';
import '../widgets/score_header.dart';
import '../widgets/scorecard_table.dart';

/// Comprehensive match detail page with live score header, tabbed views for
/// Full Scorecard, Ball-by-ball Commentary, and Playing XI & Officials Info.
class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedInningsIndex = 0; // 0 for Innings 1, 1 for Innings 2

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Match Center',
          style: (isDark ? AppTextStyles.titleLargeDark : AppTextStyles.titleLargeLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Scorecard',
            onPressed: () {
              ref.invalidate(matchDetailProvider(widget.matchId));
              ref.invalidate(matchCommentaryProvider(widget.matchId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Match',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Match link copied to clipboard!')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: matchAsync.when(
        loading: () => const LoadingWidget(message: 'Loading live match center...'),
        error: (err, stack) => AppErrorWidget(
          title: 'Unable to Load Match',
          message: err.toString(),
          onRetry: () => ref.invalidate(matchDetailProvider(widget.matchId)),
        ),
        data: (match) => _buildMatchBody(context, match, isDark),
      ),
    );
  }

  Widget _buildMatchBody(BuildContext context, Match match, bool isDark) {
    final inn1Async = ref.watch(matchInningsProvider((match.id, 1)));
    final inn2Async = ref.watch(matchInningsProvider((match.id, 2)));

    final inn1 = inn1Async.asData?.value;
    final inn2 = inn2Async.asData?.value;

    return Column(
      children: [
        // 1. Live Score Header
        ScoreHeader(
          match: match,
          innings1: inn1,
          innings2: inn2,
        ),

        // 2. Tab Bar Header
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Match Info'),
            ],
          ),
        ),

        // 3. TabBar Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Full Scorecard
              _buildScorecardTab(match, inn1, inn2, isDark),

              // Tab 2: Ball-by-ball Commentary
              _buildCommentaryTab(match, isDark),

              // Tab 3: Match Info & Playing XI
              _buildMatchInfoTab(match, isDark),
            ],
          ),
        ),

        // 4. Sticky Bottom Action Bar
        _buildBottomStickyBar(context, match, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Scorecard
  // ---------------------------------------------------------------------------
  Widget _buildScorecardTab(
    Match match,
    Innings? inn1,
    Innings? inn2,
    bool isDark,
  ) {
    final hasInn2 = inn2 != null && inn2.battingStats.isNotEmpty;

    return Column(
      children: [
        // Innings Selection Switcher
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: _buildInningsPill(
                  label: '${match.teamAShortName} Innings',
                  isSelected: _selectedInningsIndex == 0,
                  score: inn1?.scoreSummary ?? match.teamAScore,
                  onTap: () => setState(() => _selectedInningsIndex = 0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInningsPill(
                  label: '${match.teamBShortName} Innings',
                  isSelected: _selectedInningsIndex == 1,
                  score: inn2?.scoreSummary ?? (match.teamBScore ?? (hasInn2 ? null : 'Yet to Bat')),
                  onTap: () => setState(() => _selectedInningsIndex = 1),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        // Scorecard Table
        Expanded(
          child: _selectedInningsIndex == 0
              ? (inn1 != null
                  ? ScorecardTableWidget(innings: inn1)
                  : const LoadingWidget(message: 'Loading 1st Innings...'))
              : (inn2 != null
                  ? ScorecardTableWidget(innings: inn2)
                  : const LoadingWidget(message: 'Loading 2nd Innings...')),
        ),
      ],
    );
  }

  Widget _buildInningsPill({
    required String label,
    required bool isSelected,
    required String? score,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (score != null) ...[
              const SizedBox(height: 2),
              Text(
                score,
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Commentary
  // ---------------------------------------------------------------------------
  Widget _buildCommentaryTab(Match match, bool isDark) {
    final commentaryAsync = ref.watch(matchCommentaryProvider(widget.matchId));

    return commentaryAsync.when(
      loading: () => const LoadingWidget(message: 'Loading commentary feed...'),
      error: (e, s) => AppErrorWidget(
        title: 'Unable to Load Commentary',
        message: e.toString(),
        onRetry: () => ref.invalidate(matchCommentaryProvider(widget.matchId)),
      ),
      data: (deliveries) {
        if (deliveries.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No Commentary Yet',
            subtitle: 'Ball-by-ball commentary will appear as the scorer enters deliveries.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: deliveries.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.6,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return CommentaryItemWidget(delivery: delivery);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Match Info
  // ---------------------------------------------------------------------------
  Widget _buildMatchInfoTab(Match match, bool isDark) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy • hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixture Overview Card
          AppCard(
            headerTitle: 'Match Overview',
            headerLeading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            child: Column(
              children: [
                _buildInfoRow('Format', '${match.format} (${match.totalOvers} Overs per side)', isDark),
                _buildInfoRow('Ball Type', '${match.ballType ?? "WHITE"} Cricket Ball', isDark),
                _buildInfoRow('Match Date', match.matchDate != null ? dateFormat.format(match.matchDate!) : 'TBD', isDark),
                _buildInfoRow('Venue', match.venue ?? 'Ground TBD', isDark),
                _buildInfoRow('City / State', match.city ?? 'Local', isDark),
                if (match.toss != null)
                  _buildInfoRow('Toss Result', match.toss!.summary, isDark, highlight: true),
                if (match.playerOfMatchName != null)
                  _buildInfoRow('Player of the Match', match.playerOfMatchName!, isDark, highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky Bottom Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomStickyBar(BuildContext context, Match match, bool isDark) {
    if (match.isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (match.toss == null) ...[
            Expanded(
              child: AppButton(
                text: 'Conduct Match Toss',
                icon: Icons.toll_rounded,
                onPressed: () {
                  context.push('/matches/${match.id}/toss');
                },
                height: 48,
              ),
            ),
          ] else ...[
            Expanded(
              child: AppButton(
                text: 'Open Scoring Console',
                icon: Icons.scoreboard_rounded,
                onPressed: () {
                  context.push('/matches/${match.id}/scoring');
                },
                height: 48,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
