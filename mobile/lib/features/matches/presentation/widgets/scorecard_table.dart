import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import '../../domain/entities/innings.dart';

/// Professional cricket scorecard table widget presenting detailed batting performances,
/// bowling spells, extras breakdown, and fall of wickets.
class ScorecardTableWidget extends StatelessWidget {
  final Innings innings;

  const ScorecardTableWidget({
    super.key,
    required this.innings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // 1. Batting Section
          // -------------------------------------------------------------------
          _buildSectionHeader('BATTING', innings.battingTeamName, isDark),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Batting Table Header
                _buildBattingHeader(isDark),

                // Batters Rows
                if (innings.battingStats.isNotEmpty)
                  ...innings.battingStats.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stat = entry.value;
                    return _buildBatterRow(stat, isDark, idx % 2 == 1);
                  })
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Batting card will be populated as play begins.',
                      style: TextStyle(
                        color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Extras Row
                _buildExtrasRow(innings.extras, isDark),

                // Total Summary Row
                _buildTotalSummaryRow(innings, isDark),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------------------
          // 2. Bowling Section
          // -------------------------------------------------------------------
          _buildSectionHeader('BOWLING', innings.bowlingTeamName, isDark),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Bowling Table Header
                _buildBowlingHeader(isDark),

                // Bowler Rows
                if (innings.bowlingStats.isNotEmpty)
                  ...innings.bowlingStats.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stat = entry.value;
                    return _buildBowlerRow(stat, isDark, idx % 2 == 1);
                  })
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No bowling records for this innings yet.',
                      style: TextStyle(
                        color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 3. Fall of Wickets Section
          // -------------------------------------------------------------------
          if (innings.fallOfWickets.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('FALL OF WICKETS', null, isDark),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: innings.fallOfWickets.map((fow) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      fow.summary,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? teamName, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.primary,
          ),
        ),
        if (teamName != null)
          Text(
            teamName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Batting Table
  // ---------------------------------------------------------------------------

  Widget _buildBattingHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isDark ? const Color(0xFF1E2631) : const Color(0xFFF5F7FA),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('BATTER', style: _tableColHeaderStyle(isDark)),
          ),
          _buildColHeader('R', 32, isDark, highlight: true),
          _buildColHeader('B', 30, isDark),
          _buildColHeader('4s', 28, isDark),
          _buildColHeader('6s', 28, isDark),
          _buildColHeader('SR', 48, isDark),
        ],
      ),
    );
  }

  Widget _buildBatterRow(BattingStat stat, bool isDark, bool isAlt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isAlt
          ? (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.012))
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Batter Name & not-out star
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stat.playerName,
                            style: (isDark
                                    ? AppTextStyles.labelMediumDark
                                    : AppTextStyles.labelMediumLight)
                                .copyWith(
                              fontWeight: stat.isNotOut ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (stat.isNotOut) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.dismissalText,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: stat.isNotOut
                            ? AppColors.success
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        fontStyle: stat.isNotOut ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // R, B, 4s, 6s, SR
              SizedBox(
                width: 32,
                child: Text(
                  '${stat.runs}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${stat.balls}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${stat.fours}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${stat.sixes}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  stat.strikeRate.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasRow(InningsExtras extras, bool isDark) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Extras',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                extras.summary,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          Text(
            '${extras.total}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryRow(Innings innings, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              const SizedBox(width: 8),
              Text(
                '(${innings.oversFormatted} Overs, RR: ${innings.runRateFormatted})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          Text(
            '${innings.totalRuns}/${innings.totalWickets}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bowling Table
  // ---------------------------------------------------------------------------

  Widget _buildBowlingHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isDark ? const Color(0xFF1E2631) : const Color(0xFFF5F7FA),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('BOWLER', style: _tableColHeaderStyle(isDark)),
          ),
          _buildColHeader('O', 30, isDark),
          _buildColHeader('M', 26, isDark),
          _buildColHeader('R', 32, isDark),
          _buildColHeader('W', 28, isDark, highlight: true),
          _buildColHeader('ECON', 48, isDark),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(BowlingStat stat, bool isDark, bool isAlt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isAlt
          ? (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.012))
          : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              stat.playerName,
              style: (isDark
                      ? AppTextStyles.labelMediumDark
                      : AppTextStyles.labelMediumLight)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              stat.oversFormatted,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '${stat.maidens}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${stat.runs}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${stat.wickets}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              stat.economy.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableColHeaderStyle(bool isDark) {
    return TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }

  Widget _buildColHeader(String text, double width, bool isDark, {bool highlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: 0.4,
          color: highlight
              ? AppColors.primary
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}
