// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_init_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appInitService)
final appInitServiceProvider = AppInitServiceProvider._();

final class AppInitServiceProvider
    extends $FunctionalProvider<AppInitService, AppInitService, AppInitService>
    with $Provider<AppInitService> {
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

String _$appInitServiceHash() => r'b1f167f4a7d7f92bc73221be8f39055bfc972b0c';

/// The master provider that Bootstraps the entire app

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

/// The master provider that Bootstraps the entire app

final class AppStartupProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// The master provider that Bootstraps the entire app
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'bd6912f6dc0324ae05b4357d310c094a91a645d2';
