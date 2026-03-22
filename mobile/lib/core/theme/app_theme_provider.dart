import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_colors.dart';
import '../storage/storage_provider.dart';

part 'app_theme_provider.g.dart';

/// Manages the application theme state.
@Riverpod(keepAlive: true)
class AppTheme extends _$AppTheme with WidgetsBindingObserver {
  @override
  AppColors build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));

    final bool? savedIsDark = ref.watch(storageServiceProvider).isDarkMode;
    if (savedIsDark != null) {
      return savedIsDark ? DarkColors() : LightColors();
    }

    return _getSystemTheme();
  }

  AppColors _getSystemTheme() {
    final Brightness systemBrightness =
        PlatformDispatcher.instance.platformBrightness;
    return systemBrightness == Brightness.dark ? DarkColors() : LightColors();
  }

  @override
  void didChangePlatformBrightness() {
    final bool? savedIsDark = ref.read(storageServiceProvider).isDarkMode;
    if (savedIsDark == null) {
      state = _getSystemTheme();
    }
    super.didChangePlatformBrightness();
  }

  /// Toggles between light and dark mode and saves preference.
  Future<void> toggleTheme() async {
    final bool isCurrentlyDark = state is DarkColors;
    final bool newIsDark = !isCurrentlyDark;

    await ref.read(storageServiceProvider).setDarkMode(newIsDark);
    state = newIsDark ? DarkColors() : LightColors();
  }
}
