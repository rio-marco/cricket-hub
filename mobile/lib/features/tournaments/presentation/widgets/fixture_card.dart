import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

/// Card widget displaying match fixture with opposing teams, schedule, venue,
/// and match result or live status.
class FixtureCard extends StatelessWidget {
  final dynamic fixture;
  final VoidCallback? onTap;

  const FixtureCard({
    super.key,
    required this.fixture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);

    // Parse fixture attributes
    final matchNumber = fixture['matchNumber'];
    final round = fixture['round']?.toString() ??
        fixture['title']?.toString() ??
        (matchNumber != null ? 'Match #$matchNumber' : 'Match');
    final status = (fixture['status']?.toString() ?? 'UPCOMING').toUpperCase();

    // Teams
    final teamAData = fixture['teamA'];
    final teamBData = fixture['teamB'];

    final teamAName = _extractTeamName(teamAData, 'Team A');
    final teamBName = _extractTeamName(teamBData, 'Team B');
    final teamAShort = _extractShortName(teamAData, teamAName);
    final teamBShort = _extractShortName(teamBData, teamBName);

    // Venue & Date
    final venue = fixture['venue']?.toString() ?? 'TBD';
    final rawDate = fixture['matchDate'] ?? fixture['date'];
    DateTime? matchDate;
    if (rawDate != null) {
      matchDate = rawDate is DateTime ? rawDate : DateTime.tryParse(rawDate.toString());
    }

    final dateFormatted = matchDate != null
        ? DateFormat('EEE, dd MMM • hh:mm a').format(matchDate)
        : 'Schedule to be announced';

    // Result or Live Score
    final result = fixture['result'];
    String? resultText;
    if (result is Map) {
      resultText = result['description']?.toString() ?? result['margin']?.toString();
    } else if (fixture['resultText'] != null) {
      resultText = fixture['resultText'].toString();
    }

    final liveScore = fixture['score']?.toString();

    final isLive = status == 'LIVE';
    final isCompleted = status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLive ? AppColors.liveRed.withOpacity(0.5) : borderColor,
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? AppColors.liveRed.withOpacity(0.08)
                : (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta: Round Name & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            round,
                            style: (isDark ? AppTextStyles.labelSmallDark : AppTextStyles.labelSmallLight)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(status),
                  ],
                ),

                const SizedBox(height: 12),

                // Teams Face-off Row
                Row(
                  children: [
                    // Team A
                    Expanded(
                      child: Row(
                        children: [
                          _buildTeamCircle(teamAShort, AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teamAName,
                              style: (isDark
                                      ? AppTextStyles.titleSmallDark
                                      : AppTextStyles.titleSmallLight)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VS Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Team B
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              teamBName,
                              textAlign: TextAlign.end,
                              style: (isDark
                                      ? AppTextStyles.titleSmallDark
                                      : AppTextStyles.titleSmallLight)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTeamCircle(teamBShort, AppColors.secondaryLight),
                        ],
                      ),
                    ),
                  ],
                ),

                // Live score or Result Banner
                if (isLive && liveScore != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.liveRed.withOpacity(0.2)),
                    ),
                    child: Text(
                      liveScore,
                      style: const TextStyle(
                        color: AppColors.liveRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else if (isCompleted && resultText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Text(
                      resultText,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                const SizedBox(height: 8),

                // Bottom row: Schedule date & venue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date & Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Venue
                    Row(
                      children: [
                        Icon(
                          Icons.stadium_outlined,
                          size: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          venue,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCircle(String shortName, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
      ),
      child: Center(
        child: Text(
          shortName,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;
    String label = status;

    switch (status) {
      case 'LIVE':
        bg = AppColors.liveRed;
        textColor = Colors.white;
        label = 'LIVE';
        break;
      case 'COMPLETED':
        bg = AppColors.success.withOpacity(0.12);
        textColor = AppColors.success;
        label = 'RESULT';
        break;
      case 'TOSS':
        bg = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange;
        label = 'TOSS';
        break;
      case 'CANCELLED':
      case 'ABANDONED':
        bg = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey;
        break;
      case 'UPCOMING':
      default:
        bg = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        label = 'UPCOMING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _extractTeamName(dynamic teamData, String fallback) {
    if (teamData is Map) {
      return teamData['name']?.toString() ?? fallback;
    }
    if (teamData is String && teamData.isNotEmpty) return teamData;
    return fallback;
  }

  String _extractShortName(dynamic teamData, String full) {
    if (teamData is Map && teamData['shortName'] != null) {
      return teamData['shortName'].toString();
    }
    final words = full.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return full.isNotEmpty ? full.substring(0, full.length >= 3 ? 3 : full.length).toUpperCase() : 'TM';
  }
}
