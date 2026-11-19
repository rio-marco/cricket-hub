import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Clean and engaging empty state widget for screens and lists when no data is available.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double iconSize;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final IconData? actionIcon;
  final Widget? customIllustration;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.sports_cricket_outlined,
    this.iconSize = 64.0,
    this.actionText,
    this.onActionPressed,
    this.actionIcon,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                width: iconSize + 36,
                height: iconSize + 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: (isDark
                      ? AppTextStyles.titleLargeDark
                      : AppTextStyles.titleLargeLight)
                  .copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: (isDark
                        ? AppTextStyles.bodyMediumDark
                        : AppTextStyles.bodyMediumLight)
                    .copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
            ],

            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: AppButton(
                  text: actionText!,
                  icon: actionIcon ?? Icons.add_rounded,
                  onPressed: onActionPressed,
                  height: 48,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
