import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Error state presentation widget featuring an error icon banner, user-friendly
/// description, and an optional retry action button.
class AppErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;
  final double iconSize;

  const AppErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We encountered an unexpected error while loading cricket data.',
    this.onRetry,
    this.retryText = 'Try Again',
    this.icon = Icons.error_outline_rounded,
    this.iconSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft rounded icon badge
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.error,
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
            const SizedBox(height: 10),

            // Description message
            Text(
              message,
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

            if (onRetry != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 180,
                child: AppButton(
                  text: retryText,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
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
