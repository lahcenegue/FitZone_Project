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

String _$appInitServiceHash() => r'77c88b95f65e2db080fb58f15772e192773b7a45';

@ProviderFor(appStartup)
final appStartupProvider = AppStartupProvider._();

final class AppStartupProvider
    extends
        $FunctionalProvider<
          AsyncValue<StartupStatus>,
          StartupStatus,
          FutureOr<StartupStatus>
        >
    with $FutureModifier<StartupStatus>, $FutureProvider<StartupStatus> {
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
  $FutureProviderElement<StartupStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StartupStatus> create(Ref ref) {
    return appStartup(ref);
  }
}

String _$appStartupHash() => r'603fc44ef88885f8bfee77cb2b1e46b35bf97c45';
