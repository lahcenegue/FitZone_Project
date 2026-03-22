import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/storage_provider.dart';

part 'app_locale_provider.g.dart';

/// Manages the application locale state.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale with WidgetsBindingObserver {
  @override
  Locale build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    final String? savedLang = ref.watch(storageServiceProvider).locale;
    if (savedLang != null) {
      return Locale(savedLang);
    }

    return _getSystemLocale();
  }

  Locale _getSystemLocale() {
    final String systemLanguage =
        PlatformDispatcher.instance.locale.languageCode;
    return systemLanguage == 'ar' ? const Locale('ar') : const Locale('en');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final String? savedLang = ref.read(storageServiceProvider).locale;
    if (savedLang == null && locales != null && locales.isNotEmpty) {
      final String newSystemLang = locales.first.languageCode;
      state = newSystemLang == 'ar' ? const Locale('ar') : const Locale('en');
    }
    super.didChangeLocales(locales);
  }

  /// Sets the application locale manually and saves preference.
  Future<void> setLocale(String langCode) async {
    await ref.read(storageServiceProvider).setLocale(langCode);
    state = Locale(langCode);
  }
}
