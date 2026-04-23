// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exploreApiService)
final exploreApiServiceProvider = ExploreApiServiceProvider._();

final class ExploreApiServiceProvider
    extends
        $FunctionalProvider<
          ExploreApiService,
          ExploreApiService,
          ExploreApiService
        >
    with $Provider<ExploreApiService> {
  ExploreApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreApiServiceHash();

  @$internal
  @override
  $ProviderElement<ExploreApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExploreApiService create(Ref ref) {
    return exploreApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreApiService>(value),
    );
  }
}

String _$exploreApiServiceHash() => r'bd3829a6e84b2bfec5d33b648a353fd812d89e84';

@ProviderFor(ExploreFilter)
final exploreFilterProvider = ExploreFilterProvider._();

final class ExploreFilterProvider
    extends $NotifierProvider<ExploreFilter, ExploreFilterState> {
  ExploreFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreFilterHash();

  @$internal
  @override
  ExploreFilter create() => ExploreFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreFilterState>(value),
    );
  }
}

String _$exploreFilterHash() => r'fa6300fbb0effb645fc4c83b5a1b798355c64802';

abstract class _$ExploreFilter extends $Notifier<ExploreFilterState> {
  ExploreFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExploreFilterState, ExploreFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExploreFilterState, ExploreFilterState>,
              ExploreFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedPlace)
final selectedPlaceProvider = SelectedPlaceProvider._();

final class SelectedPlaceProvider
    extends $NotifierProvider<SelectedPlace, GymModel?> {
  SelectedPlaceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPlaceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPlaceHash();

  @$internal
  @override
  SelectedPlace create() => SelectedPlace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GymModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GymModel?>(value),
    );
  }
}

String _$selectedPlaceHash() => r'039d4b3e922570a028c7a227a5ba6830ca9aa199';

abstract class _$SelectedPlace extends $Notifier<GymModel?> {
  GymModel? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GymModel?, GymModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GymModel?, GymModel?>,
              GymModel?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nearbyPlaces)
final nearbyPlacesProvider = NearbyPlacesProvider._();

final class NearbyPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GymModel>>,
          List<GymModel>,
          FutureOr<List<GymModel>>
        >
    with $FutureModifier<List<GymModel>>, $FutureProvider<List<GymModel>> {
  NearbyPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyPlacesHash();

  @$internal
  @override
  $FutureProviderElement<List<GymModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GymModel>> create(Ref ref) {
    return nearbyPlaces(ref);
  }
}

String _$nearbyPlacesHash() => r'b0675cb6b6562f87d60c6fa3e9d305e293c106ef';
