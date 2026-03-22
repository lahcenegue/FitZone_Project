import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

/// Centralized service for local storage operations.
class StorageService {
  final SharedPreferences _prefs;
  static final Logger _logger = Logger('StorageService');

  StorageService(this._prefs);

  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_is_dark';
  static const String _sportsDataKey = 'sports_data';
  static const String _sportsVersionKey = 'sports_version';

  String? get locale => _prefs.getString(_languageKey);

  Future<void> setLocale(String langCode) async {
    await _prefs.setString(_languageKey, langCode);
    _logger.info('Language saved: $langCode');
  }

  bool? get isDarkMode => _prefs.getBool(_themeKey);

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
    _logger.info('Theme mode saved. Dark mode: $isDark');
  }

  double get sportsVersion => _prefs.getDouble(_sportsVersionKey) ?? 0.0;

  Future<void> setSportsVersion(double version) async {
    await _prefs.setDouble(_sportsVersionKey, version);
  }

  List<dynamic> get sportsData {
    final String? data = _prefs.getString(_sportsDataKey);
    if (data == null) return [];
    try {
      return json.decode(data) as List<dynamic>;
    } catch (e, stackTrace) {
      _logger.severe('Failed to decode sports data', e, stackTrace);
      return [];
    }
  }

  Future<void> setSportsData(List<dynamic> data) async {
    try {
      await _prefs.setString(_sportsDataKey, json.encode(data));
      _logger.info('Sports data cached successfully.');
    } catch (e, stackTrace) {
      _logger.severe('Failed to encode sports data', e, stackTrace);
    }
  }

  Future<void> clearCache() async {
    await _prefs.clear();
    _logger.info('Local storage cleared.');
  }
}
