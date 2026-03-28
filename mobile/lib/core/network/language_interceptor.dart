import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_provider.dart';

/// Intercepts outgoing HTTP requests to inject the active App Language.
class LanguageInterceptor extends Interceptor {
  final Ref ref;

  LanguageInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Fetch the currently saved language from local storage
    final String? currentLanguage = ref.read(storageServiceProvider).locale;

    // Inject the Accept-Language header. Default to 'ar' if null.
    options.headers['Accept-Language'] = currentLanguage ?? 'ar';

    super.onRequest(options, handler);
  }
}
