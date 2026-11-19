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

/// Clean and focused Forgot Password screen for password reset recovery.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final identifier = _identifierController.text.trim();
    final userId = await ref
        .read(authStateProvider.notifier)
        .forgotPassword(emailOrPhone: identifier);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent successfully. Check your inbox!'),
          backgroundColor: AppColors.success,
        ),
      );

      context.push(
        AppRoutes.resetPassword,
        extra: {'userId': userId, 'identifier': identifier},
      );
    } else {
      final authState = ref.read(authStateProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Could not send reset code. Please check the information and try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              title: 'Forgot Password?',
              subtitle: 'Enter your registered email or phone number to receive a verification OTP',
              icon: Icons.lock_reset_rounded,
              height: 230,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),

            // Card Form Container
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
                        // Description text
                        Text(
                          'Password Recovery',
                          style: (isDark
                                  ? AppTextStyles.titleMediumDark
                                  : AppTextStyles.titleMediumLight)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We will send a 6-digit one-time password (OTP) to verify your account identity before setting a new password.',
                          style: (isDark
                                  ? AppTextStyles.bodyMediumDark
                                  : AppTextStyles.bodyMediumLight)
                              .copyWith(color: AppColors.textSecondaryLight, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Email / Phone Field
                        AppTextField(
                          controller: _identifierController,
                          labelText: 'Email or Phone Number',
                          hintText: 'e.g. captain@crickethub.app or +91 9876543210',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.contact_mail_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email or phone number';
                            }
                            if (value.trim().length < 4) {
                              return 'Please enter a valid credential';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleSendOtp(),
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        AppButton(
                          text: 'Send Verification OTP',
                          isLoading: _isLoading,
                          icon: Icons.send_rounded,
                          onPressed: _handleSendOtp,
                        ),
                        const SizedBox(height: 20),

                        // Back to Login link
                        Center(
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Back to Sign In',
                                    style: AppTextStyles.labelMediumLight.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
