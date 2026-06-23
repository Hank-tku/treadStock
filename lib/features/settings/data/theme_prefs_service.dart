import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme mode choice (system / light / dark) via
/// SharedPreferences. Mirrors the OnboardingService pattern.
///
/// Stored values: 'system' | 'light' | 'dark' (see [ThemeMode] mapping).
/// Absence of a stored value is treated as 'system' (follow the platform).
class ThemePrefsService {
  static const _key = 'theme_mode';

  /// Read the persisted theme mode. Defaults to [ThemeMode.system] when unset
  /// or when the stored value is unrecognized.
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return _parse(raw);
  }

  /// Persist the given theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _serialize(mode));
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
