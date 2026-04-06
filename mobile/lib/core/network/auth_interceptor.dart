import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../config/api_constants.dart';
import '../storage/secure_storage_provider.dart';

/// Intercepts outgoing HTTP requests to inject the Authorization Bearer token.
class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Logger _logger = Logger('AuthInterceptor');

  AuthInterceptor(this.ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Define endpoints that do not require authentication
      final List<String> publicEndpoints = [
        ApiConstants.register,
        ApiConstants.login,
        ApiConstants.verifyEmail,
        ApiConstants.resendVerification,
      ];

      // Check if the current request path matches any public endpoint
      final bool isPublicEndpoint = publicEndpoints.any(
        (endpoint) => options.path.contains(endpoint),
      );

      // Only attach the Authorization header if it is NOT a public endpoint
      if (!isPublicEndpoint) {
        final secureStorage = ref.read(secureStorageServiceProvider);
        final String? accessToken = await secureStorage.getAccessToken();

        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
      }
    } catch (e) {
      _logger.severe('Failed to inject auth token', e);
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Note: Future implementation for Token Refresh (401 Unauthorized)
    // will be handled here to automatically refresh the token and retry.
    if (err.response?.statusCode == 401) {
      _logger.warning('Unauthorized request (401). Token might be expired.');
    }
    super.onError(err, handler);
  }
}
