import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../config/api_constants.dart';
import '../storage/secure_storage_provider.dart';
import '../storage/storage_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../routing/app_router.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Logger _logger = Logger('AuthInterceptor');

  // Architecture Fix: Queue management variables to handle Race Conditions
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this.ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final List<String> publicEndpoints = [
        ApiConstants.register,
        ApiConstants.login,
        ApiConstants.verifyEmail,
        ApiConstants.resendVerification,
        ApiConstants.requestPasswordReset,
        ApiConstants.confirmPasswordReset,
        ApiConstants.refreshToken,
      ];

      final bool isPublicEndpoint = publicEndpoints.any(
        (endpoint) => options.path.contains(endpoint),
      );

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
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiConstants.refreshToken)) {
      _logger.warning(
        'Unauthorized request (401) for ${err.requestOptions.path}.',
      );

      // Architecture Fix: Prevent Race Condition when multiple endpoints fail 401 simultaneously.
      if (_isRefreshing) {
        _logger.info('Token refresh already in progress. Queuing request...');
        try {
          // Wait for the ongoing refresh to finish
          final bool isRefreshed = await _refreshCompleter!.future;
          if (isRefreshed) {
            return await _retryOriginalRequest(err, handler);
          } else {
            return handler.next(err);
          }
        } catch (e) {
          return handler.next(err);
        }
      }

      _isRefreshing = true;
      _refreshCompleter = Completer<bool>();

      _logger.info('Attempting token refresh...');
      final bool isRefreshed = await _attemptTokenRefresh();

      _isRefreshing = false;
      _refreshCompleter!.complete(isRefreshed);

      if (isRefreshed) {
        _logger.info(
          'Token refreshed successfully. Retrying original request.',
        );
        return await _retryOriginalRequest(err, handler);
      } else {
        _logger.severe(
          'Fatal: Token refresh failed completely. Session expired.',
        );
        _triggerLogoutWipeout();
        return handler.next(err);
      }
    }

    super.onError(err, handler);
  }

  Future<void> _retryOriginalRequest(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final String? newAccessToken = await secureStorage.getAccessToken();

      if (newAccessToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      }

      // Using an isolated Dio instance to avoid recursive loops
      final isolatedRetryDio = Dio();
      final response = await isolatedRetryDio.fetch(err.requestOptions);

      return handler.resolve(response);
    } on DioException catch (retryError) {
      _logger.severe(
        'Retry request failed for ${err.requestOptions.path}.',
        retryError,
      );
      return handler.next(retryError);
    }
  }

  void _triggerLogoutWipeout() async {
    try {
      // 1. Clear secure tokens (JWT)
      await ref.read(secureStorageServiceProvider).clearAll();

      // 2. Clear cached user data (SharedPreferences)
      await ref.read(storageServiceProvider).clearCachedUser();

      // 3. Invalidate AuthController to notify the entire app
      ref.invalidate(authControllerProvider);

      // 4. Force redirect to login
      ref.read(goRouterProvider).go(RoutePaths.login);
    } catch (e) {
      _logger.severe('Error during logout wipeout', e);
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final String? refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warning('No refresh token found.');
        return false;
      }

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

        if (newAccessToken != null && newRefreshToken != null) {
          await secureStorage.saveTokens(
            accessToken: newAccessToken.toString(),
            refreshToken: newRefreshToken.toString(),
          );
          return true;
        }
      }
      return false;
    } catch (error) {
      _logger.severe('Refresh token expired or invalid API error', error);
      return false;
    }
  }
}
