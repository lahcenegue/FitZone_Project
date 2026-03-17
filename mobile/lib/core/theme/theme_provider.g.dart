// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to manage application theme.
/// Listens to system theme changes automatically using WidgetsBindingObserver.

@ProviderFor(ThemeNotifier)
final themeProvider = ThemeNotifierProvider._();

/// Provider to manage application theme.
/// Listens to system theme changes automatically using WidgetsBindingObserver.
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, AppColors> {
  /// Provider to manage application theme.
  /// Listens to system theme changes automatically using WidgetsBindingObserver.
  ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppColors value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppColors>(value),
    );
  }
}

String _$themeNotifierHash() => r'28478976c44a249100673c8b09cf5798c7954608';

/// Provider to manage application theme.
/// Listens to system theme changes automatically using WidgetsBindingObserver.

abstract class _$ThemeNotifier extends $Notifier<AppColors> {
  AppColors build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppColors, AppColors>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppColors, AppColors>,
              AppColors,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
