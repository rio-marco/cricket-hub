import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';

/// Settings state representing device configurations and local preferences.
class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String apiUrl;
  final String appVersion;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.apiUrl = AppConstants.devBaseUrl,
    this.appVersion = AppConstants.appVersion,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? apiUrl,
    String? appVersion,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      apiUrl: apiUrl ?? this.apiUrl,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SecureStorage _storage;

  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final savedTheme = await _storage.getString(AppConstants.themeModeKey);
      ThemeMode mode = ThemeMode.system;
      if (savedTheme == 'dark') {
        mode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        mode = ThemeMode.light;
      }

      state = state.copyWith(
        themeMode: mode,
        apiUrl: AppConfig.current.apiBaseUrl,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await _storage.saveString(AppConstants.themeModeKey, val);
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> updateApiUrl(String url) async {
    state = state.copyWith(apiUrl: url);
    AppConfig.setEnvironment(
      AppEnvironment.development,
      customBaseUrl: url,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SettingsNotifier(storage);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
