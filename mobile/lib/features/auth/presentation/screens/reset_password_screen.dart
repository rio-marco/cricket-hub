import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/core/routing/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/password_strength_indicator.dart';

/// Reset Password Screen with OTP input, new password strength meter,
/// password confirmation, and a celebratory success dialog.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? initialOtp;

  const ResetPasswordScreen({
    super.key,
    this.userId,
    this.initialOtp,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _newPassword = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOtp != null) {
      _otpController.text = widget.initialOtp!;
    }
    _newPasswordController.addListener(() {
      setState(() {
        _newPassword = _newPasswordController.text;
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final targetUserId = widget.userId ?? 'pending_reset';

    final success = await ref.read(authStateProvider.notifier).resetPassword(
      userId: targetUserId,
      otp: otp,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else {
      final authState = ref.read(authStateProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Failed to reset password. Please check your verification code.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated celebratory icon badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Password Reset Complete!',
                  style: AppTextStyles.headlineSmallLight.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  'Your password has been updated successfully. You can now log in with your new credentials.',
                  style: AppTextStyles.bodyMediumLight.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Continue to Login Button
                AppButton(
                  text: 'Continue to Sign In',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            AuthHeader(
              title: 'Reset Password',
              subtitle: 'Enter the verification OTP and choose a strong new password',
              icon: Icons.vpn_key_rounded,
              height: 230,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),

            // Form Card
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // OTP Code Field
                        AppTextField(
                          controller: _otpController,
                          labelText: 'Verification OTP',
                          hintText: 'Enter 6-digit OTP code',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.pin_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the verification OTP';
                            }
                            if (value.trim().length < 4) {
                              return 'Please enter the complete OTP code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // New Password Field
                        AppTextField(
                          controller: _newPasswordController,
                          labelText: 'New Password',
                          hintText: 'Enter new password',
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        // Strength indicator
                        PasswordStrengthIndicator(password: _newPassword),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        AppTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm New Password',
                          hintText: 'Re-enter new password',
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleResetPassword(),
                        ),
                        const SizedBox(height: 28),

                        // Reset Action Button
                        AppButton(
                          text: 'Reset Password',
                          isLoading: _isLoading,
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _handleResetPassword,
                        ),
                        const SizedBox(height: 20),

                        // Back to Sign In
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: Text(
                              'Return to Sign In',
                              style: AppTextStyles.labelMediumLight.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
