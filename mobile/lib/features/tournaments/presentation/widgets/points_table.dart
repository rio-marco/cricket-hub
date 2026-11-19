import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import '../../domain/entities/tournament_team.dart';

/// Professional cricket tournament points table widget with team logos,
/// columns for P, W, L, NR, PTS, NRR, top-3 medal highlights, and qualified separators.
class PointsTableWidget extends StatelessWidget {
  final List<TournamentTeam> teams;
  final int playoffCutoff;
  final void Function(TournamentTeam team)? onTeamTap;

  const PointsTableWidget({
    super.key,
    required this.teams,
    this.playoffCutoff = 4,
    this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 48,
                color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No standings data yet',
                style: (isDark ? AppTextStyles.titleMediumDark : AppTextStyles.titleMediumLight)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Matches need to be completed to populate the points table.',
                textAlign: TextAlign.center,
                style: isDark ? AppTextStyles.bodySmallDark : AppTextStyles.bodySmallLight,
              ),
            ],
          ),
        ),
      );
    }

    // Sort teams by points (descending), then netRunRate (descending)
    final sortedTeams = List<TournamentTeam>.from(teams)
      ..sort((a, b) {
        if (b.points != a.points) {
          return b.points.compareTo(a.points);
        }
        return b.netRunRate.compareTo(a.netRunRate);
      });

    final tableBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);

    return Container(
      decoration: BoxDecoration(
        color: tableBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          _buildTableHeader(isDark),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedTeams.length,
            separatorBuilder: (context, index) {
              final isCutoff = index == playoffCutoff - 1 && playoffCutoff < sortedTeams.length;
              if (isCutoff) {
                return _buildQualificationDivider(isDark);
              }
              return Divider(
                height: 1,
                thickness: 0.6,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              );
            },
            itemBuilder: (context, index) {
              final team = sortedTeams[index];
              final rank = index + 1;
              return _buildTableRow(context, team, rank, isDark, index % 2 == 1);
            },
          ),

          // Legend Footer
          _buildLegendFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondaryLight,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#',
              style: _headerTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text('TEAM', style: _headerTextStyle),
          ),
          _buildHeaderCol('P', 28),
          _buildHeaderCol('W', 28),
          _buildHeaderCol('L', 28),
          _buildHeaderCol('NR', 28),
          _buildHeaderCol('PTS', 36, isHighlighted: true),
          _buildHeaderCol('NRR', 54),
        ],
      ),
    );
  }

  TextStyle get _headerTextStyle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 0.6,
      );

  Widget _buildHeaderCol(String text, double width, {bool isHighlighted = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHighlighted ? AppColors.primaryLight : Colors.white,
          fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    TournamentTeam team,
    int rank,
    bool isDark,
    bool isAlternating,
  ) {
    Color? rowBgColor;
    if (rank <= 3) {
      if (rank == 1) {
        rowBgColor = AppColors.trophyGold.withOpacity(isDark ? 0.08 : 0.07);
      } else if (rank == 2) {
        rowBgColor = AppColors.trophySilver.withOpacity(isDark ? 0.06 : 0.05);
      } else if (rank == 3) {
        rowBgColor = AppColors.trophyBronze.withOpacity(isDark ? 0.06 : 0.05);
      }
    } else if (isAlternating) {
      rowBgColor = isDark
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.015);
    }

    return Material(
      color: rowBgColor ?? Colors.transparent,
      child: InkWell(
        onTap: onTeamTap != null ? () => onTeamTap!(team) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Rank badge
              SizedBox(
                width: 28,
                child: Center(child: _buildRankBadge(rank, isDark)),
              ),
              const SizedBox(width: 8),

              // Team Avatar & Name
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _buildTeamAvatar(team, rank, isDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team.teamName,
                        style: (isDark
                                ? AppTextStyles.labelMediumDark
                                : AppTextStyles.labelMediumLight)
                            .copyWith(
                          fontWeight: rank <= playoffCutoff
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // P, W, L, NR
              _buildDataCol('${team.played}', 28, isDark),
              _buildDataCol('${team.won}', 28, isDark, textColor: AppColors.success),
              _buildDataCol('${team.lost}', 28, isDark, textColor: isDark ? const Color(0xFFE57373) : AppColors.error),
              _buildDataCol('${team.noResult}', 28, isDark),

              // PTS (Bold orange or primary)
              SizedBox(
                width: 36,
                child: Text(
                  '${team.points}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),

              // NRR
              SizedBox(
                width: 54,
                child: Text(
                  team.formattedNrr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: team.netRunRate >= 0
                        ? AppColors.success
                        : (isDark ? const Color(0xFFE57373) : AppColors.error),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isDark) {
    if (rank == 1) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.trophyGold,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '1',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.trophySilver,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.trophyBronze,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTeamAvatar(TournamentTeam team, int rank, bool isDark) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          team.teamShortName,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCol(String val, double width, bool isDark, {Color? textColor}) {
    return SizedBox(
      width: width,
      child: Text(
        val,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor ??
              (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQualificationDivider(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'TOP $playoffCutoff QUALIFY FOR PLAYOFFS',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF7F7F7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'P: Played • W: Won • L: Lost • NR: No Result',
            style: TextStyle(
              color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
              fontSize: 10,
            ),
          ),
          Text(
            'PTS: Points • NRR: Net Run Rate',
            style: TextStyle(
              color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
