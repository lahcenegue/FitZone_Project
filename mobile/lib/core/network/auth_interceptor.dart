import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../config/api_constants.dart';
import '../storage/secure_storage_provider.dart';

/// Intercepts outgoing HTTP requests to inject the Authorization Bearer token
/// and securely handles silent token refreshes without circular dependencies.
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
        ApiConstants.requestPasswordReset,
        ApiConstants.confirmPasswordReset,
      ];

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _logger.warning('Unauthorized request (401). Token might be expired.');

      final bool isRefreshed = await _attemptTokenRefresh();

      if (isRefreshed) {
        _logger.info(
          'Token refreshed successfully. Retrying original request.',
        );

        try {
          final secureStorage = ref.read(secureStorageServiceProvider);
          final String? newAccessToken = await secureStorage.getAccessToken();

          if (newAccessToken != null) {
            // Update the header of the failed request with the new valid token
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
          }

          // ARCHITECTURE FIX: Use a completely isolated Dio instance to retry the request.
          // Using ref.read(dioClientProvider) here causes a fatal Circular Dependency crash.
          // Since err.requestOptions already contains the full URL, body, and headers (including language),
          // a fresh, isolated Dio instance will execute it perfectly.
          final isolatedRetryDio = Dio();
          final response = await isolatedRetryDio.fetch(err.requestOptions);

          return handler.resolve(response);
        } on DioException catch (retryError) {
          _logger.severe(
            'Retry request failed after successful token refresh.',
            retryError,
          );
          return handler.next(retryError);
        }
      } else {
        _logger.severe(
          'Token refresh failed completely. User session has expired.',
        );
        final secureStorage = ref.read(secureStorageServiceProvider);
        await secureStorage.clearTokens();
        // Return the error so the UI/Repository can handle the logout logic
        return super.onError(err, handler);
      }
    }

    // Pass any non-401 errors down the chain
    super.onError(err, handler);
  }

  /// Attempts to securely refresh the JWT tokens via the API.
  Future<bool> _attemptTokenRefresh() async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final String? refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warning('No refresh token found. Cannot perform refresh.');
        return false;
      }

      // Create a dedicated Dio instance exclusively for refreshing tokens
      // to avoid triggering the same interceptor loops.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['access'];
        final newRefreshToken = response.data['refresh'];

        if (newAccessToken != null) {
          await secureStorage.saveTokens(
            accessToken: newAccessToken.toString(),
            refreshToken: newRefreshToken != null
                ? newRefreshToken.toString()
                : refreshToken, // Fallback to old refresh token if backend doesn't rotate it
          );
          return true;
        }
      }
      return false;
    } catch (error) {
      _logger.severe('Exception occurred during token refresh process', error);
      return false;
    }
  }
}
