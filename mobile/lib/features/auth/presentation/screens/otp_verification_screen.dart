import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/routing/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/otp_input_field.dart';

/// Beautiful 6-digit OTP verification screen with auto-focus advancement,
/// 60-second countdown resend timer, auto-verify trigger, and error handling.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? destination;
  final String? userId;

  const OtpVerificationScreen({
    super.key,
    this.destination,
    this.userId,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _initialCountdown = 60;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdown;
  bool _canResend = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = _initialCountdown;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() {
      _hasError = false;
    });

    if (value.isNotEmpty) {
      // Auto-advance to next box if not on the last digit
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered: unfocus and auto-verify
        _focusNodes[index].unfocus();
        if (_currentOtp.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    final otp = _currentOtp;
    if (otp.length < _otpLength) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the OTP.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = widget.userId?.trim();
    if (userId == null || userId.isEmpty) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Please register again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authStateProvider.notifier).verifyOTP(
      userId: userId,
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account verified successfully! Welcome to Cricket Hub.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.home);
    } else {
      setState(() => _hasError = true);
      final authState = ref.read(authStateProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Invalid or expired OTP. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final userId = widget.userId?.trim();
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Please register again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(authStateProvider.notifier)
        .resendOTP(userId: userId);

    if (!mounted) return;

    if (!success) {
      final authState = ref.read(authStateProvider);
      final errorMsg = authState is AuthError
          ? authState.message
          : 'Could not send a new code. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
      );
      return;
    }

    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _hasError = false);
    _focusNodes[0].requestFocus();
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New verification code sent!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetDestination = widget.destination ?? 'your email/phone';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            AuthHeader(
              title: 'Verify Your Account',
              subtitle: 'We sent a 6-digit verification code to $targetDestination',
              icon: Icons.mark_email_read_rounded,
              height: 230,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),

            // Main Verification Card
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
                  child: Column(
                    children: [
                      // Subtitle Instructions
                      Text(
                        'Enter 6-Digit Code',
                        style: (isDark
                                ? AppTextStyles.titleMediumDark
                                : AppTextStyles.titleMediumLight)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please check your SMS and email inbox.',
                        style: (isDark
                                ? AppTextStyles.bodySmallDark
                                : AppTextStyles.bodySmallLight)
                            .copyWith(color: AppColors.textSecondaryLight),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // 6 Digit Input Boxes
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final boxSize = (constraints.maxWidth - (5 * 8)) / 6;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_otpLength, (index) {
                              return OtpInputField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                autoFocus: index == 0,
                                hasError: _hasError,
                                size: boxSize.clamp(38.0, 52.0),
                                onChanged: (value) => _onDigitChanged(index, value),
                                onBackspace: () => _onBackspace(index),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Countdown / Resend Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _canResend
                                ? AppColors.textDisabledLight
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          if (!_canResend) ...[
                            Text(
                              'Resend code in ',
                              style: AppTextStyles.bodySmallLight.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              _formatTimer(_secondsRemaining),
                              style: AppTextStyles.labelMediumLight.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...[
                            InkWell(
                              onTap: _handleResend,
                              child: Text(
                                'Resend Code',
                                style: AppTextStyles.labelMediumLight.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Verify Action Button
                      AppButton(
                        text: 'Verify & Proceed',
                        isLoading: isLoading,
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _handleVerify,
                      ),
                      const SizedBox(height: 16),

                      // Change Number / Return
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Change Email / Phone',
                          style: AppTextStyles.labelMediumLight.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
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
    );
  }
}

/// Type alias to support uppercase naming convention
typedef OTPVerificationScreen = OtpVerificationScreen;
