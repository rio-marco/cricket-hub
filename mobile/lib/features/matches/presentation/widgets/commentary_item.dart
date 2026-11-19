import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

/// Interactive ball-by-ball commentary item widget showing over number,
/// color-coded run/wicket badge, players involved, and detailed commentary narrative.
class CommentaryItemWidget extends StatelessWidget {
  final dynamic delivery;

  const CommentaryItemWidget({
    super.key,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse attributes
    final overNum = delivery['over'] != null
        ? delivery['over'].toString()
        : '${delivery['overNumber'] ?? 0}.${delivery['ballNumber'] ?? 1}';

    final runs = delivery['runs'] is num ? (delivery['runs'] as num).toInt() : 0;
    final isBoundary = delivery['isBoundary'] == true;
    final isSix = delivery['isSix'] == true;
    final isWicket = delivery['isWicket'] == true;
    final isWide = delivery['isWide'] == true;
    final isNoBall = delivery['isNoBall'] == true;

    final batsman = delivery['batsman']?.toString();
    final bowler = delivery['bowler']?.toString();
    final text = delivery['text']?.toString() ??
        (delivery['description']?.toString() ?? 'No commentary available for this delivery.');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Over number badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              overNum,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Run / Event Circular Badge
          _buildOutcomeBadge(
            runs: runs,
            isBoundary: isBoundary,
            isSix: isSix,
            isWicket: isWicket,
            isWide: isWide,
            isNoBall: isNoBall,
          ),
          const SizedBox(width: 12),

          // Commentary Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bowler to Batsman line if present
                if (bowler != null && batsman != null) ...[
                  Row(
                    children: [
                      Text(
                        '$bowler to $batsman',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      if (isWicket) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.wicket.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'WICKET',
                            style: TextStyle(
                              color: AppColors.wicket,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                ],

                // Commentary Text
                Text(
                  text,
                  style: (isDark
                          ? AppTextStyles.bodyMediumDark
                          : AppTextStyles.bodyMediumLight)
                      .copyWith(
                    height: 1.4,
                    fontSize: 13,
                    fontWeight: (isBoundary || isWicket) ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeBadge({
    required int runs,
    required bool isBoundary,
    required bool isSix,
    required bool isWicket,
    required bool isWide,
    required bool isNoBall,
  }) {
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    if (isWicket) {
      bgColor = AppColors.wicket;
      label = 'W';
    } else if (isSix) {
      bgColor = AppColors.boundarySix;
      label = '6';
    } else if (isBoundary || runs == 4) {
      bgColor = AppColors.boundaryFour;
      label = '4';
    } else if (isWide) {
      bgColor = AppColors.warning;
      label = 'Wd';
    } else if (isNoBall) {
      bgColor = AppColors.warning;
      label = 'Nb';
    } else if (runs == 0) {
      bgColor = const Color(0xFF9E9E9E);
      label = '•';
    } else {
      bgColor = AppColors.primary;
      label = '$runs';
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: label == '•' ? 16 : 11,
          ),
        ),
      ),
    );
  }
}
