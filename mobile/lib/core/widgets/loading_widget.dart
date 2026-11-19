import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Centered loading spinner with optional status message and full-screen overlay option.
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  final Color? color;
  final double size;
  final double strokeWidth;

  const LoadingWidget({
    super.key,
    this.message,
    this.isFullScreen = false,
    this.color,
    this.size = 36.0,
    this.strokeWidth = 3.2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spinnerColor = color ?? AppColors.primary;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: (isDark
                    ? AppTextStyles.bodyMediumDark
                    : AppTextStyles.bodyMediumLight)
                .copyWith(
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Container(
        color: isDark
            ? AppColors.backgroundDark.withOpacity(0.85)
            : Colors.white.withOpacity(0.85),
        alignment: Alignment.center,
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }
}
