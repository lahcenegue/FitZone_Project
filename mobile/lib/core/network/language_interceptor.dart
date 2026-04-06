import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_locale_provider.dart';

/// Intercepts outgoing HTTP requests to inject the active App Language.
class LanguageInterceptor extends Interceptor {
  final Ref ref;

  LanguageInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Read the actual active locale directly from the AppLocaleProvider
    // This accurately reflects either the user's choice or the device's system language.
    final locale = ref.read(appLocaleProvider);

    // Inject the Accept-Language header (e.g., 'en' or 'ar')
    options.headers['Accept-Language'] = locale.languageCode;

    super.onRequest(options, handler);
  }
}
