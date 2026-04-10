import 'package:dio/dio.dart';
import 'package:fitzone/core/network/auth_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/api_constants.dart';
import 'language_interceptor.dart';

part 'api_provider.g.dart';

/// Provides a globally configured Dio client for all API requests.
/// Professional setup with clear separation of interceptors.
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );

  // Attach interceptors in a clean batch
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LanguageInterceptor(ref),
    LogInterceptor(
      requestBody: true,
      responseBody: false, // Set to true only for heavy debugging
      error: true,
    ),
  ]);

  return dio;
}
