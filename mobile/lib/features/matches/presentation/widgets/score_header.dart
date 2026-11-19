import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';

/// Visually stunning live score header widget for match detail screens.
/// Displays live team scores, overs, run rates, target formula, and animated live indicator.
class ScoreHeader extends StatefulWidget {
  final Match match;
  final Innings? innings1;
  final Innings? innings2;

  const ScoreHeader({
    super.key,
    required this.match,
    this.innings1,
    this.innings2,
  });

  @override
  State<ScoreHeader> createState() => _ScoreHeaderState();
}

class _ScoreHeaderState extends State<ScoreHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.match.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ScoreHeader oldWidget) {
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
    final match = widget.match;
    final inn1 = widget.innings1;
    final inn2 = widget.innings2;

    // Calculate score strings
    String team1Score = match.teamAScore ?? (inn1 != null ? inn1.scoreSummary : '-');
    String team2Score = match.teamBScore ?? (inn2 != null ? inn2.scoreSummary : '-');

    // Run rates and target
    String? crr;
    String? rrr;
    String? targetEquation;

    if (match.isLive) {
      if (match.currentInnings == 1 && inn1 != null) {
        crr = 'CRR: ${inn1.runRateFormatted}';
      } else if (match.currentInnings == 2 && inn2 != null) {
        crr = 'CRR: ${inn2.runRateFormatted}';
        if (inn1 != null && inn2.target != null) {
          final neededRuns = inn2.target! - inn2.totalRuns;
          final maxBalls = match.totalOvers * 6;
          final remainingBalls = maxBalls - inn2.totalBalls;
          if (remainingBalls > 0 && neededRuns > 0) {
            final requiredRate = (neededRuns / (remainingBalls / 6.0));
            rrr = 'RRR: ${requiredRate.toStringAsFixed(2)}';
            targetEquation = 'Need $neededRuns runs in $remainingBalls balls';
          } else if (neededRuns <= 0) {
            targetEquation = '${match.teamBName} won the match!';
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF101B2B),
            Color(0xFF1B2838),
            Color(0xFF24364D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          // Match Top Meta: Tournament & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.tournamentName != null
                      ? '${match.tournamentName} • ${match.format}'
                      : '${match.format} Match',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildLiveOrStatusBadge(match),
            ],
          ),

          const SizedBox(height: 18),

          // Opposing Teams Face-off & Big Scores
          Row(
            children: [
              // Team A Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTeamBadge(match.teamAShortName, AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.teamAName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team1Score,
                      style: TextStyle(
                        color: match.currentInnings == 1 && match.isLive
                            ? AppColors.primaryLight
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // VS Divider Center
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

              // Team B Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            match.teamBName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTeamBadge(match.teamBShortName, AppColors.secondaryLight),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2Score,
                      style: TextStyle(
                        color: match.currentInnings == 2 && match.isLive
                            ? AppColors.primaryLight
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Run Rate and Equation Bar
          if (crr != null || rrr != null || targetEquation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (crr != null)
                        Text(
                          crr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      if (rrr != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          rrr,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (targetEquation != null)
                    Expanded(
                      child: Text(
                        targetEquation,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Toss or Result text summary banner
          const SizedBox(height: 12),
          _buildTossOrResultFooter(match),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String short, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
      ),
      child: Center(
        child: Text(
          short,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveOrStatusBadge(Match match) {
    if (match.isLive) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.liveRed.withOpacity(_pulseAnimation.value * 0.3 + 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.liveRed, width: 1.2),
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
                  'LIVE MATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: match.statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: match.statusColor, width: 1),
      ),
      child: Text(
        match.statusDisplayName,
        style: TextStyle(
          color: match.statusColor,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildTossOrResultFooter(Match match) {
    String text;
    IconData icon;
    Color iconColor;

    if (match.isCompleted) {
      text = match.result?.description ?? 'Match Completed';
      icon = Icons.emoji_events_rounded;
      iconColor = AppColors.trophyGold;
    } else if (match.toss != null) {
      text = match.toss!.summary;
      icon = Icons.toll_rounded;
      iconColor = AppColors.primaryLight;
    } else if (match.venue != null) {
      text = 'Venue: ${match.venue} ${match.city != null ? '(${match.city})' : ''}';
      icon = Icons.stadium_outlined;
      iconColor = Colors.white70;
    } else {
      text = 'Live Scoring on Cricket Hub';
      icon = Icons.sports_cricket;
      iconColor = AppColors.primary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
