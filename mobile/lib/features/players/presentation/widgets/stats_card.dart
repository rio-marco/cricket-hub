import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reusable cricket metric presentation card with icon, headline value,
/// secondary label, and optional gradient accent.
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final bool hasGradient;
  final LinearGradient? customGradient;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.hasGradient = false,
    this.customGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveGradient = hasGradient
        ? (customGradient ?? AppColors.primaryLinearGradient)
        : null;

    final effectiveBgColor = effectiveGradient != null
        ? null
        : (isDark ? AppColors.cardDark : AppColors.cardLight);

    final textColor = hasGradient
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final subtextColor = hasGradient
        ? Colors.white70
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    final effectiveIconColor = hasGradient
        ? Colors.white
        : (iconColor ?? AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: effectiveGradient == null
            ? Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: hasGradient
                ? (AppColors.primary).withOpacity(0.3)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasGradient
                            ? Colors.white.withOpacity(0.2)
                            : (iconColor ?? AppColors.primary).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: effectiveIconColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: (isDark
                              ? AppTextStyles.headlineMediumDark
                              : AppTextStyles.headlineMediumLight)
                          .copyWith(
                        color: hasGradient
                            ? Colors.white
                            : (valueColor ?? textColor),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: (isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmallLight)
                          .copyWith(
                        color: subtextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}
