import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../storage/storage_provider.dart';

part 'auth_intent_provider.g.dart';

enum AuthIntentType { none, buyGymSubscription, buyTrainerSubscription }

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

class AuthIntentService {
  final SharedPreferences _prefs;
  static final Logger _logger = Logger('AuthIntentService');
  static const String _intentKey = 'pending_auth_intent';

  AuthIntentService(this._prefs);

  Future<void> saveIntent(AuthIntent intent) async {
    try {
      final String jsonString = jsonEncode(intent.toJson());
      await _prefs.setString(_intentKey, jsonString);
      _logger.info('Saved Auth Intent: ${intent.type.name}');
    } catch (e) {
      _logger.severe('Failed to save Auth Intent', e);
    }
  }

  AuthIntent getIntent() {
    final String? jsonString = _prefs.getString(_intentKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        return AuthIntent.fromJson(jsonDecode(jsonString));
      } catch (e) {
        _logger.severe('Failed to parse Auth Intent', e);
      }
    }
    return AuthIntent();
  }

  Future<void> clearIntent() async {
    await _prefs.remove(_intentKey);
    _logger.info('Cleared Auth Intent.');
  }
}

@Riverpod(keepAlive: true)
AuthIntentService authIntentService(Ref ref) {
  return AuthIntentService(ref.watch(sharedPrefsProvider));
}
