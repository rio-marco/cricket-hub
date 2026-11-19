import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

/// Password strength levels
enum PasswordStrength {
  none(0, 'Too Short', Colors.transparent),
  weak(1, 'Weak', AppColors.error),
  fair(2, 'Fair', AppColors.warning),
  good(3, 'Good', Color(0xFF1E88E5)),
  strong(4, 'Strong', AppColors.success);

  final int score;
  final String label;
  final Color color;

  const PasswordStrength(this.score, this.label, this.color);
}

/// Animated password strength indicator widget with 4 color-coded segments,
/// live strength label, and requirement checklist hints.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  /// Evaluates password strength based on length, digits, casing, and symbols
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    int points = 0;
    if (password.length >= 8) points++;
    if (RegExp(r'[0-9]').hasMatch(password)) points++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      points++;
    }
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) points++;

    if (points <= 1) return PasswordStrength.weak;
    if (points == 2) return PasswordStrength.fair;
    if (points == 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = calculateStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // 4 segmented animated bars
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength.score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 3 ? 6.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: isFilled
                      ? strength.color
                      : AppColors.borderLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        // Strength label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: AppTextStyles.bodySmallLight.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: AppTextStyles.labelSmallLight.copyWith(
                color: strength.color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              child: Text(strength.label),
            ),
          ],
        ),
      ],
    );
  }
}
