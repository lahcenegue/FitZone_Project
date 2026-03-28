import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/api_constants.dart';
import 'language_interceptor.dart';

part 'api_provider.g.dart';

/// Provides a globally configured Dio client for all API requests.
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

  // Attach our custom Language Interceptor
  dio.interceptors.add(LanguageInterceptor(ref));

  // Attach standard Log Interceptor for debugging in terminal
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: false, // Set to true if you need to see raw JSON responses
      error: true,
    ),
  );

  return dio;
}
