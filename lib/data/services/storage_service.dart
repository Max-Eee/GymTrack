import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyWeightUnit = 'weight_unit';
  static const String _keyHeightUnit = 'height_unit';
  static const String _keyDefaultRestTimer = 'default_rest_timer';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // First launch
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  
  Future<void> setFirstLaunchComplete() => _prefs.setBool(_keyFirstLaunch, false);

  // Theme
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  
  Future<void> setThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  // Units
  String get weightUnit => _prefs.getString(_keyWeightUnit) ?? 'kg';
  
  Future<void> setWeightUnit(String unit) => _prefs.setString(_keyWeightUnit, unit);

  String get heightUnit => _prefs.getString(_keyHeightUnit) ?? 'cm';
  
  Future<void> setHeightUnit(String unit) => _prefs.setString(_keyHeightUnit, unit);

  // Rest timer
  int get defaultRestTimer => _prefs.getInt(_keyDefaultRestTimer) ?? 90;
  
  Future<void> setDefaultRestTimer(int seconds) => _prefs.setInt(_keyDefaultRestTimer, seconds);

  // Clear all
  Future<void> clearAll() => _prefs.clear();
}
