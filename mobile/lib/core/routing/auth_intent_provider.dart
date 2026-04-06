import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../storage/storage_provider.dart';

part 'auth_intent_provider.g.dart';

/// Defines the reasons why a user was sent to the authentication flow.
enum AuthIntentType { none, buyGymSubscription, buyTrainerSubscription }

/// Represents the action the user intended to take before auth.
class AuthIntent {
  final AuthIntentType type;
  final Map<String, dynamic> payload;

  AuthIntent({this.type = AuthIntentType.none, this.payload = const {}});

  Map<String, dynamic> toJson() => {'type': type.name, 'payload': payload};

  factory AuthIntent.fromJson(Map<String, dynamic> json) {
    return AuthIntent(
      type: AuthIntentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AuthIntentType.none,
      ),
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Service to persist the user's intent across app restarts (e.g., during Email Verification).
class AuthIntentService {
  final SharedPreferences _prefs;
  static final Logger _logger = Logger('AuthIntentService');
  static const String _intentKey = 'pending_auth_intent';

  AuthIntentService(this._prefs);

  /// Saves the intent before navigating to Auth or Email App.
  Future<void> saveIntent(AuthIntent intent) async {
    final String jsonString = jsonEncode(intent.toJson());
    await _prefs.setString(_intentKey, jsonString);
    _logger.info('Saved Auth Intent: ${intent.type.name}');
  }

  /// Retrieves the saved intent after successful authentication.
  AuthIntent getIntent() {
    final String? jsonString = _prefs.getString(_intentKey);
    if (jsonString != null) {
      try {
        return AuthIntent.fromJson(jsonDecode(jsonString));
      } catch (e) {
        _logger.severe('Failed to parse Auth Intent', e);
      }
    }
    return AuthIntent(); // Returns 'none' by default
  }

  /// Clears the intent once it has been successfully handled.
  Future<void> clearIntent() async {
    await _prefs.remove(_intentKey);
    _logger.info('Cleared Auth Intent.');
  }
}

@Riverpod(keepAlive: true)
AuthIntentService authIntentService(Ref ref) {
  return AuthIntentService(ref.watch(sharedPrefsProvider));
}
