import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../../features/auth/data/models/user_model.dart';

/// Centralized service strictly for lightweight local settings and caching.
class StorageService {
  final SharedPreferences _prefs;
  static final Logger _logger = Logger('StorageService');

  StorageService(this._prefs);

  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_is_dark';
  static const String _lastLatKey = 'last_lat';
  static const String _lastLngKey = 'last_lng';
  static const String _userKey = 'cached_user_profile';

  String? get locale => _prefs.getString(_languageKey);

  Future<void> setLocale(String langCode) async {
    await _prefs.setString(_languageKey, langCode);
    _logger.info('Language saved: $langCode');
  }

  bool? get isDarkMode => _prefs.getBool(_themeKey);

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

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

  UserModel? getCachedUser() {
    final String? userJson = _prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (e) {
        _logger.severe('Failed to parse cached user', e);
        return null;
      }
    }
    return null;
  }

  Future<void> cacheUser(UserModel user) async {
    final String userJson = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, userJson);
    _logger.info('User profile cached successfully.');
  }

  Future<void> clearCachedUser() async {
    await _prefs.remove(_userKey);
    _logger.info('Cached user profile cleared.');
  }

  Future<void> clearSettings() async {
    await _prefs.clear();
    _logger.info('Local settings cleared.');
  }
}
