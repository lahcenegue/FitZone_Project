// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketplaceApiService)
final marketplaceApiServiceProvider = MarketplaceApiServiceProvider._();

final class MarketplaceApiServiceProvider
    extends
        $FunctionalProvider<
          MarketplaceApiService,
          MarketplaceApiService,
          MarketplaceApiService
        >
    with $Provider<MarketplaceApiService> {
  MarketplaceApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketplaceApiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketplaceApiServiceHash();

  @$internal
  @override
  $ProviderElement<MarketplaceApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketplaceApiService create(Ref ref) {
    return marketplaceApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketplaceApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketplaceApiService>(value),
    );
  }
}

String _$marketplaceApiServiceHash() =>
    r'14be45ccc7ced427a9b1e5cb4643f653552189ba';

@ProviderFor(MarketplaceController)
final marketplaceControllerProvider = MarketplaceControllerProvider._();

final class MarketplaceControllerProvider
    extends $AsyncNotifierProvider<MarketplaceController, MarketplaceState> {
  MarketplaceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketplaceControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketplaceControllerHash();

  @$internal
  @override
  MarketplaceController create() => MarketplaceController();
}

String _$marketplaceControllerHash() =>
    r'53872503c0411bc3f4a1d79ab874ef49ef4e1efb';

abstract class _$MarketplaceController
    extends $AsyncNotifier<MarketplaceState> {
  FutureOr<MarketplaceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MarketplaceState>, MarketplaceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MarketplaceState>, MarketplaceState>,
              AsyncValue<MarketplaceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
