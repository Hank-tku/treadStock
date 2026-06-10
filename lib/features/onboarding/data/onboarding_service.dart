import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing onboarding state via SharedPreferences.
class OnboardingService {
  static const _completedKey = 'onboarding_completed';
  static const _styleKey = 'investment_style';

  /// Whether the user has already completed onboarding.
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  /// Mark onboarding as completed.
  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  /// Save the user's chosen investment style.
  Future<void> saveStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, style);
  }

  /// Get the user's saved investment style, or null if not set.
  Future<String?> getStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_styleKey);
  }
}
