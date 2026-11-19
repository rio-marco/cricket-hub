import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import '../../domain/entities/match.dart';

/// Interactive match card for matches listings with animated LIVE indicator,
/// opposing teams face-off, current innings scores, and match results.
class MatchCard extends StatefulWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.match.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.match.isLive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.match.isLive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final match = widget.match;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = match.isLive
        ? AppColors.liveRed.withOpacity(0.4)
        : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8));

    // Date formatting
    String dateFormatted = 'Schedule TBD';
    if (match.matchDate != null) {
      final now = DateTime.now();
      final isToday = match.matchDate!.year == now.year &&
          match.matchDate!.month == now.month &&
          match.matchDate!.day == now.day;
      if (isToday) {
        dateFormatted = 'Today, ${DateFormat('hh:mm a').format(match.matchDate!)}';
      } else {
        dateFormatted = DateFormat('EEE, dd MMM • hh:mm a').format(match.matchDate!);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: match.isLive ? 1.4 : 1),
        boxShadow: [
          BoxShadow(
            color: match.isLive
                ? AppColors.liveRed.withOpacity(0.08)
                : (isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.05)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Tournament & Status Badge
              _buildTopMetaBar(context, isDark, dateFormatted),

              // Match Body: Teams and Scores
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  children: [
                    // Team A Row
                    _buildTeamRow(
                      name: match.teamAName,
                      shortName: match.teamAShortName,
                      score: match.teamAScore,
                      isBattingNow: match.isLive && match.currentInnings == 1,
                      isDark: isDark,
                      badgeColor: AppColors.primary,
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                    const SizedBox(height: 12),

                    // Team B Row
                    _buildTeamRow(
                      name: match.teamBName,
                      shortName: match.teamBShortName,
                      score: match.teamBScore,
                      isBattingNow: match.isLive && match.currentInnings == 2,
                      isDark: isDark,
                      badgeColor: AppColors.secondaryLight,
                    ),
                  ],
                ),
              ),

              // Bottom Result / Status Footer
              _buildBottomResultBanner(match, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetaBar(
    BuildContext context,
    bool isDark,
    String dateFormatted,
  ) {
    final match = widget.match;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2631) : const Color(0xFFF7F8FA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tournament Name & Format
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.format,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.tournamentName ?? (match.title ?? 'Cricket Match'),
                    style: (isDark
                            ? AppTextStyles.labelSmallDark
                            : AppTextStyles.labelSmallLight)
                        .copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge
          _buildStatusBadge(match),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Match match) {
    if (match.isLive) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.liveRed.withOpacity(_pulseAnimation.value * 0.2 + 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.liveRed, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.liveRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.liveRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final statusColor = match.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        match.statusDisplayName,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required String shortName,
    required String? score,
    required bool isBattingNow,
    required bool isDark,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        // Team Circle Icon
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor.withOpacity(0.4), width: 1.2),
          ),
          child: Center(
            child: Text(
              shortName,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Team Name & Batting indicator
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: (isDark
                          ? AppTextStyles.titleMediumDark
                          : AppTextStyles.titleMediumLight)
                      .copyWith(
                    fontWeight: isBattingNow ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isBattingNow) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.sports_cricket,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),

        // Score (if available)
        if (score != null && score.isNotEmpty)
          Text(
            score,
            style: (isDark
                    ? AppTextStyles.titleMediumDark
                    : AppTextStyles.titleMediumLight)
                .copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isBattingNow
                  ? AppColors.primary
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          )
        else
          Text(
            widget.match.isUpcoming ? 'Yet to bat' : '-',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomResultBanner(Match match, bool isDark) {
    String message;
    Color messageColor;

    if (match.isLive) {
      if (match.currentInnings == 2 && match.toss != null) {
        message = 'Innings 2 in progress • Live updates on ball commentary';
      } else if (match.toss != null) {
        message = match.toss!.summary;
      } else {
        message = 'Match is currently in progress';
      }
      messageColor = AppColors.liveRed;
    } else if (match.isCompleted) {
      message = match.result?.description ??
          (match.result?.winnerName != null
              ? '${match.result!.winnerName} won the match'
              : 'Match Completed');
      messageColor = AppColors.success;
    } else if (match.status == 'TOSS') {
      message = match.toss?.summary ?? 'Toss underway';
      messageColor = AppColors.warning;
    } else {
      // Upcoming
      final venuePart = match.venue != null ? 'at ${match.venue}' : '';
      message = 'Match starts ${match.matchDate != null ? DateFormat('hh:mm a').format(match.matchDate!) : ''} $venuePart';
      messageColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            match.isCompleted
                ? Icons.emoji_events_outlined
                : (match.isLive ? Icons.sports_score_rounded : Icons.schedule_rounded),
            size: 13,
            color: messageColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: messageColor,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
