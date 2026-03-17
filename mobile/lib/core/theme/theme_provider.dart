import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitzone/core/theme/app_colors.dart';

part 'theme_provider.g.dart';

/// Provider to manage application theme.
/// Listens to system theme changes automatically using WidgetsBindingObserver.
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier with WidgetsBindingObserver {
  bool _isManualOverride = false;

  @override
  AppColors build() {
    // Start listening to system changes
    WidgetsBinding.instance.addObserver(this);

    // Stop listening if the provider is disposed (memory leak prevention)
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    return _getSystemTheme();
  }

  /// Helper method to fetch current system theme
  AppColors _getSystemTheme() {
    final Brightness systemBrightness =
        PlatformDispatcher.instance.platformBrightness;
    return systemBrightness == Brightness.dark ? DarkColors() : LightColors();
  }

  /// Triggered automatically by Flutter when the system theme changes
  @override
  void didChangePlatformBrightness() {
    // Only apply system theme if the user hasn't manually selected a theme in the app
    if (!_isManualOverride) {
      state = _getSystemTheme();
    }
    super.didChangePlatformBrightness();
  }

  /// Toggles the theme manually (e.g., via a button in settings)
  void toggleTheme() {
    _isManualOverride = true; // Mark as manually changed
    if (state is LightColors) {
      state = DarkColors();
    } else {
      state = LightColors();
    }
  }
}
