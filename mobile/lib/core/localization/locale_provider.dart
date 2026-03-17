import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

/// Provider to manage application language.
/// Listens to system language changes automatically using WidgetsBindingObserver.
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier with WidgetsBindingObserver {
  bool _isManualOverride = false;

  @override
  Locale build() {
    // Start listening to system changes
    WidgetsBinding.instance.addObserver(this);

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    return _getSystemLocale();
  }

  /// Helper method to fetch current system language
  Locale _getSystemLocale() {
    final String systemLanguage =
        PlatformDispatcher.instance.locale.languageCode;
    return systemLanguage == 'ar' ? const Locale('ar') : const Locale('en');
  }

  /// Triggered automatically by Flutter when the system language changes
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (!_isManualOverride && locales != null && locales.isNotEmpty) {
      final String newSystemLang = locales.first.languageCode;
      state = newSystemLang == 'ar' ? const Locale('ar') : const Locale('en');
    }
    super.didChangeLocales(locales);
  }

  /// Changes the application language manually (e.g., via settings)
  void setLocale(Locale locale) {
    _isManualOverride = true;
    state = locale;
  }
}
