import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

/// Available application deployment environments.
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Central configuration for the Cricket Hub mobile application.
class AppConfig {
  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final String socketUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
  final bool enableCrashReporting;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.socketUrl,
    this.connectTimeout = AppConstants.connectTimeout,
    this.receiveTimeout = AppConstants.receiveTimeout,
    required this.enableLogging,
    required this.enableCrashReporting,
  });

  /// Factory constructor for development environment.
  factory AppConfig.development({String? customBaseUrl}) {
    final base = customBaseUrl ?? AppConstants.devBaseUrl;
    final socket = base.replaceAll('/api/v1', '');
    return AppConfig(
      environment: AppEnvironment.development,
      appName: '${AppConstants.appName} Dev',
      apiBaseUrl: base,
      socketUrl: socket,
      enableLogging: true,
      enableCrashReporting: false,
    );
  }

  /// Factory constructor for staging environment.
  factory AppConfig.staging() {
    return const AppConfig(
      environment: AppEnvironment.staging,
      appName: '${AppConstants.appName} Staging',
      apiBaseUrl: AppConstants.stagingBaseUrl,
      socketUrl: 'https://staging-api.crickethub.app',
      enableLogging: true,
      enableCrashReporting: true,
    );
  }

  /// Factory constructor for production environment.
  factory AppConfig.production() {
    return const AppConfig(
      environment: AppEnvironment.production,
      appName: AppConstants.appName,
      apiBaseUrl: AppConstants.prodBaseUrl,
      socketUrl: 'https://api.crickethub.app',
      enableLogging: false,
      enableCrashReporting: true,
    );
  }

  /// Creates config based on environment enum.
  factory AppConfig.fromEnvironment(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return AppConfig.development();
      case AppEnvironment.staging:
        return AppConfig.staging();
      case AppEnvironment.production:
        return AppConfig.production();
    }
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  // Global static instance (default is development)
  static AppConfig _current = AppConfig.development();
  static AppConfig get current => _current;

  static void setEnvironment(AppEnvironment environment, {String? customBaseUrl}) {
    switch (environment) {
      case AppEnvironment.development:
        _current = AppConfig.development(customBaseUrl: customBaseUrl);
        break;
      case AppEnvironment.staging:
        _current = AppConfig.staging();
        break;
      case AppEnvironment.production:
        _current = AppConfig.production();
        break;
    }
  }
}

/// Riverpod provider for application configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.current;
});
