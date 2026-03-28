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

  static const String _amenitiesDataKey = 'amenities_data';
  static const String _amenitiesVersionKey = 'amenities_version';

  static const String _citiesDataKey = 'cities_data';
  static const String _citiesVersionKey = 'cities_version';

  String? get locale => _prefs.getString(_languageKey);

  Future<void> setLocale(String langCode) async {
    await _prefs.setString(_languageKey, langCode);
    _logger.info('Language saved: $langCode');
  }

  bool? get isDarkMode => _prefs.getBool(_themeKey);

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  // --- Sports ---
  double get sportsVersion => _prefs.getDouble(_sportsVersionKey) ?? 0.0;
  Future<void> setSportsVersion(double version) async =>
      await _prefs.setDouble(_sportsVersionKey, version);

  List<dynamic> get sportsData => _decodeList(_sportsDataKey);
  Future<void> setSportsData(List<dynamic> data) async =>
      await _encodeList(_sportsDataKey, data);

  // --- Amenities ---
  double get amenitiesVersion => _prefs.getDouble(_amenitiesVersionKey) ?? 0.0;
  Future<void> setAmenitiesVersion(double version) async =>
      await _prefs.setDouble(_amenitiesVersionKey, version);

  List<dynamic> get amenitiesData => _decodeList(_amenitiesDataKey);
  Future<void> setAmenitiesData(List<dynamic> data) async =>
      await _encodeList(_amenitiesDataKey, data);

  // --- Cities ---
  double get citiesVersion => _prefs.getDouble(_citiesVersionKey) ?? 0.0;
  Future<void> setCitiesVersion(double version) async =>
      await _prefs.setDouble(_citiesVersionKey, version);

  List<dynamic> get citiesData => _decodeList(_citiesDataKey);
  Future<void> setCitiesData(List<dynamic> data) async =>
      await _encodeList(_citiesDataKey, data);

  // --- Helper Methods ---
  List<dynamic> _decodeList(String key) {
    final String? data = _prefs.getString(key);
    if (data == null) return [];
    try {
      return json.decode(data) as List<dynamic>;
    } catch (e, stackTrace) {
      _logger.severe('Failed to decode data for key: $key', e, stackTrace);
      return [];
    }
  }

  Future<void> _encodeList(String key, List<dynamic> data) async {
    try {
      await _prefs.setString(key, json.encode(data));
      _logger.info('Data cached successfully for key: $key');
    } catch (e, stackTrace) {
      _logger.severe('Failed to encode data for key: $key', e, stackTrace);
    }
  }

  Future<void> clearCache() async {
    await _prefs.clear();
    _logger.info('Local storage cleared.');
  }
}
