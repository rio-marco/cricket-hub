import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

/// Premium interactive button widget with gradient background, scale animations,
/// loading spinner, icon support, and disabled states.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.leading,
    this.trailing,
    this.width,
    this.height = AppConstants.minButtonHeight,
    this.borderRadius = AppConstants.buttonBorderRadius,
    this.textStyle,
    this.customColor,
  });

  /// Factory for secondary navy button
  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = AppConstants.minButtonHeight,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      variant: AppButtonVariant.secondary,
      icon: icon,
      leading: leading,
      trailing: trailing,
      width: width,
      height: height,
    );
  }

  /// Factory for outlined button
  factory AppButton.outlined({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
    double height = AppConstants.minButtonHeight,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      variant: AppButtonVariant.outlined,
      icon: icon,
      leading: leading,
      trailing: trailing,
      width: width,
      height: height,
    );
  }

  /// Factory for text-only button
  factory AppButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    double? width,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      variant: AppButtonVariant.text,
      icon: icon,
      leading: leading,
      trailing: trailing,
      width: width,
      height: 44,
    );
  }

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isClickable =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _onTapDown(TapDownDetails details) {
    if (_isClickable) _animController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isClickable) _animController.reverse();
  }

  void _onTapCancel() {
    if (_isClickable) _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(isDark)),
            ),
          ),
          const SizedBox(width: 12),
        ] else ...[
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 8),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, size: 20, color: _getTextColor(isDark)),
            const SizedBox(width: 8),
          ],
        ],
        Text(
          widget.text,
          style: (widget.textStyle ??
                  AppTextStyles.labelLargeLight.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ))
              .copyWith(color: _getTextColor(isDark)),
        ),
        if (widget.trailing != null && !widget.isLoading) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: _getBoxDecoration(isDark),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isClickable ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: Colors.white.withOpacity(0.15),
              highlightColor: Colors.white.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: buttonContent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration(bool isDark) {
    if (widget.isDisabled) {
      return BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: widget.customColor != null
              ? null
              : AppColors.primaryLinearGradient,
          color: widget.customColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: (widget.customColor ?? AppColors.primary).withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        );

      case AppButtonVariant.secondary:
        return BoxDecoration(
          gradient: widget.customColor != null
              ? null
              : AppColors.darkLinearGradient,
          color: widget.customColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        );

      case AppButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.customColor ?? AppColors.primary,
            width: 1.6,
          ),
        );

      case AppButtonVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        );
    }
  }

  Color _getTextColor(bool isDark) {
    if (widget.isDisabled) {
      return isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E);
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return Colors.white;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return widget.customColor ?? AppColors.primary;
    }
  }
}
