import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

/// Centralized service strictly for lightweight local settings (Key-Value).

class StorageService {
  final SharedPreferences _prefs;
  static final Logger _logger = Logger('StorageService');

  StorageService(this._prefs);

  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_is_dark';
  static const String _lastLatKey = 'last_lat';
  static const String _lastLngKey = 'last_lng';

  // --- Language Management ---
  String? get locale => _prefs.getString(_languageKey);

  Future<void> setLocale(String langCode) async {
    await _prefs.setString(_languageKey, langCode);
    _logger.info('Language saved: $langCode');
  }

  // --- Theme Management ---
  bool? get isDarkMode => _prefs.getBool(_themeKey);

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  // --- Location Management (Last Known Location) ---
  LatLng? getLastLocation() {
    final double? lat = _prefs.getDouble(_lastLatKey);
    final double? lng = _prefs.getDouble(_lastLngKey);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  Future<void> setLastLocation(LatLng location) async {
    await _prefs.setDouble(_lastLatKey, location.latitude);
    await _prefs.setDouble(_lastLngKey, location.longitude);
  }

  // --- Clear Settings ---
  Future<void> clearSettings() async {
    await _prefs.clear();
    _logger.info('Local settings cleared.');
  }
}
