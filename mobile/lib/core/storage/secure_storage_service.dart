import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// Core service for handling highly sensitive data like JWT tokens.
class SecureStorageService {
  final FlutterSecureStorage _storage;
  static final Logger _logger = Logger('SecureStorageService');

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  SecureStorageService(this._storage);

  /// Saves JWT tokens securely.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
      _logger.info('Authentication tokens saved securely.');
    } catch (e, stackTrace) {
      _logger.severe('Failed to save tokens securely', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieves the access token.
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e, stackTrace) {
      _logger.severe('Failed to read access token', e, stackTrace);
      return null;
    }
  }

  /// Retrieves the refresh token.
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e, stackTrace) {
      _logger.severe('Failed to read refresh token', e, stackTrace);
      return null;
    }
  }

  /// Clears all stored tokens securely (used during Logout).
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
      _logger.info('Authentication tokens cleared securely.');
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear tokens', e, stackTrace);
    }
  }

  /// Clears all stored data (Tokens, User Info, etc.) upon logout.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
