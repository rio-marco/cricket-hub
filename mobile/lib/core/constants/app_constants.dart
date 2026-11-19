/// App-wide constants for Cricket Hub application.
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Cricket Hub';
  static const String appTagline = 'Live Cricket Scoring, Tournaments & Analytics';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Environment Base URLs
  static const String devBaseUrl = 'http://10.0.2.2:5000/api/v1';
  static const String devLocalhostUrl = 'http://localhost:5000/api/v1';
  static const String stagingBaseUrl = 'https://staging-api.crickethub.app/api/v1';
  static const String prodBaseUrl = 'https://api.crickethub.app/api/v1';

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Pagination Defaults
  static const int defaultPage = 1;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Secure Storage Keys
  static const String tokenKey = 'cricket_hub_auth_token';
  static const String refreshTokenKey = 'cricket_hub_refresh_token';
  static const String userDataKey = 'cricket_hub_user_data';
  static const String themeModeKey = 'cricket_hub_theme_mode';
  static const String onboardingCompletedKey = 'cricket_hub_onboarding_completed';
  static const String biometricsEnabledKey = 'cricket_hub_biometrics_enabled';
  static const String pushTokenKey = 'cricket_hub_push_token';

  // UI Dimensions & Geometry
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 24.0;
  static const double inputBorderRadius = 12.0;
  static const double dialogBorderRadius = 20.0;
  static const double bottomSheetRadius = 24.0;
  static const double minButtonHeight = 52.0;

  // Default Padding
  static const double screenPaddingHorizontal = 16.0;
  static const double screenPaddingVertical = 20.0;
  static const double cardPadding = 16.0;
  static const double itemSpacing = 12.0;

  // Cricket Rules Defaults
  static const int defaultOversPerInnings = 20;
  static const int defaultPlayersPerTeam = 11;
  static const int ballsPerOver = 6;
}
