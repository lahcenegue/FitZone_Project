// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_init_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the AppInitService instance.

@ProviderFor(appInitService)
final appInitServiceProvider = AppInitServiceProvider._();

/// Provides the AppInitService instance.

final class AppInitServiceProvider
    extends $FunctionalProvider<AppInitService, AppInitService, AppInitService>
    with $Provider<AppInitService> {
  /// Provides the AppInitService instance.
  AppInitServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInitServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInitServiceHash();

  @$internal
  @override
  $ProviderElement<AppInitService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppInitService create(Ref ref) {
    return appInitService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppInitService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppInitService>(value),
    );
  }
}

String _$appInitServiceHash() => r'9edb9842ee7305d7ed2310d441dcff0192a7ef8a';
