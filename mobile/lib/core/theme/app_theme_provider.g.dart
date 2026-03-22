// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the application theme state.

@ProviderFor(AppTheme)
final appThemeProvider = AppThemeProvider._();

/// Manages the application theme state.
final class AppThemeProvider extends $NotifierProvider<AppTheme, AppColors> {
  /// Manages the application theme state.
  AppThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeHash();

  @$internal
  @override
  AppTheme create() => AppTheme();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppColors value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppColors>(value),
    );
  }
}

String _$appThemeHash() => r'73c0e7dc596901cf52032687753619cb239eac20';

/// Manages the application theme state.

abstract class _$AppTheme extends $Notifier<AppColors> {
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
