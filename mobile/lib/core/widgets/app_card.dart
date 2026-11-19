import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Premium Card widget for Cricket Hub with rounded corners, subtle elevation,
/// optional gradient header banner, and interactive tap handler.
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? headerTitle;
  final String? headerSubtitle;
  final Widget? headerLeading;
  final Widget? headerTrailing;
  final bool hasGradientHeader;
  final LinearGradient? headerGradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;
  final Clip clipBehavior;

  const AppCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppConstants.cardPadding),
    this.margin,
    this.borderRadius = AppConstants.cardBorderRadius,
    this.onTap,
    this.headerTitle,
    this.headerSubtitle,
    this.headerLeading,
    this.headerTrailing,
    this.hasGradientHeader = false,
    this.headerGradient,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 1.5,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBgColor = backgroundColor ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);

    final effectiveBorderColor = borderColor ??
        (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFEEEEEE));

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerTitle != null || headerLeading != null || headerTrailing != null)
          _buildHeader(context, isDark),
        if (child != null)
          Padding(
            padding: padding,
            child: child!,
          ),
      ],
    );

    Widget cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: AppColors.primary.withOpacity(0.08),
                highlightColor: AppColors.primary.withOpacity(0.04),
                child: content,
              ),
            )
          : content,
    );

    return cardWidget;
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final effectiveGradient = headerGradient ??
        (hasGradientHeader
            ? AppColors.primaryLinearGradient
            : null);

    return Container(
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        color: effectiveGradient == null
            ? (isDark ? const Color(0xFF222222) : const Color(0xFFF7F7F7))
            : null,
        border: effectiveGradient == null
            ? Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 0.8,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (headerLeading != null) ...[
            headerLeading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (headerTitle != null)
                  Text(
                    headerTitle!,
                    style: (isDark
                            ? AppTextStyles.titleMediumDark
                            : AppTextStyles.titleMediumLight)
                        .copyWith(
                      color: hasGradientHeader
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (headerSubtitle != null)
                  Text(
                    headerSubtitle!,
                    style: (isDark
                            ? AppTextStyles.bodySmallDark
                            : AppTextStyles.bodySmallLight)
                        .copyWith(
                      color: hasGradientHeader
                          ? Colors.white.withOpacity(0.85)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (headerTrailing != null) ...[
            const SizedBox(width: 8),
            headerTrailing!,
          ],
        ],
      ),
    );
  }
}
