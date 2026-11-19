import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

/// Single OTP digit input box widget with smooth focus glow,
/// numeric filtering, backspace handling, and custom error state.
class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackspace;
  final bool autoFocus;
  final bool hasError;
  final double size;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onBackspace,
    this.autoFocus = false,
    this.hasError = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            controller.text.isEmpty) {
          onBackspace?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([focusNode, controller]),
        builder: (context, child) {
          final isFocused = focusNode.hasFocus;
          final isFilled = controller.text.isNotEmpty;

          Color borderColor;
          if (hasError) {
            borderColor = AppColors.error;
          } else if (isFocused) {
            borderColor = AppColors.primary;
          } else if (isFilled) {
            borderColor = AppColors.primary.withOpacity(0.6);
          } else {
            borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: size,
            height: size * 1.15,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isFocused || hasError ? 2.0 : 1.2,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: hasError
                            ? AppColors.error.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autoFocus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 1,
                style: AppTextStyles.headlineSmallLight.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  onChanged(value);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
