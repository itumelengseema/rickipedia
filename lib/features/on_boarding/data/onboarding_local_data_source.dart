import 'package:shared_preferences/shared_preferences.dart';

class OnboardingLocalDataSource {
  final SharedPreferencesAsync _preferences;

  OnboardingLocalDataSource(this._preferences);

  static const String _completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final completed = await _preferences.getBool(_completedKey);
    return completed ?? false;
  }

  Future<void> complete() async {
    await _preferences.setBool(_completedKey, true);
  }
}