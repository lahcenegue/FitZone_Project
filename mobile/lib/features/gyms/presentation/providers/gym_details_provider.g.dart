// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the instance of the Gyms API service using modern Riverpod approach.

@ProviderFor(gymsApiService)
final gymsApiServiceProvider = GymsApiServiceProvider._();

/// Provides the instance of the Gyms API service using modern Riverpod approach.

final class GymsApiServiceProvider
    extends $FunctionalProvider<GymsApiService, GymsApiService, GymsApiService>
    with $Provider<GymsApiService> {
  /// Provides the instance of the Gyms API service using modern Riverpod approach.
  GymsApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gymsApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gymsApiServiceHash();

  @$internal
  @override
  $ProviderElement<GymsApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GymsApiService create(Ref ref) {
    return gymsApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GymsApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GymsApiService>(value),
    );
  }
}

String _$gymsApiServiceHash() => r'0fecd545bdb72c7a18189d44e60bff4b903cc59e';

/// Fetches and caches the gym details based on the provided branch ID.

@ProviderFor(gymDetails)
final gymDetailsProvider = GymDetailsFamily._();

/// Fetches and caches the gym details based on the provided branch ID.

final class GymDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<GymDetailsModel>,
          GymDetailsModel,
          FutureOr<GymDetailsModel>
        >
    with $FutureModifier<GymDetailsModel>, $FutureProvider<GymDetailsModel> {
  /// Fetches and caches the gym details based on the provided branch ID.
  GymDetailsProvider._({
    required GymDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'gymDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gymDetailsHash();

  @override
  String toString() {
    return r'gymDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GymDetailsModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GymDetailsModel> create(Ref ref) {
    final argument = this.argument as int;
    return gymDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GymDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gymDetailsHash() => r'56f8dffae733c8c7b1a4dc3e2b47536449af3532';

/// Fetches and caches the gym details based on the provided branch ID.

final class GymDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GymDetailsModel>, int> {
  GymDetailsFamily._()
    : super(
        retry: null,
        name: r'gymDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches and caches the gym details based on the provided branch ID.

  GymDetailsProvider call(int branchId) =>
      GymDetailsProvider._(argument: branchId, from: this);

  @override
  String toString() => r'gymDetailsProvider';
}
