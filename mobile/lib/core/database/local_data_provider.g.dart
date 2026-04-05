// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches and bundles all static data from SQLite for the Explore Filters.

@ProviderFor(filterStaticData)
final filterStaticDataProvider = FilterStaticDataProvider._();

/// Fetches and bundles all static data from SQLite for the Explore Filters.

final class FilterStaticDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<FilterStaticData>,
          FilterStaticData,
          FutureOr<FilterStaticData>
        >
    with $FutureModifier<FilterStaticData>, $FutureProvider<FilterStaticData> {
  /// Fetches and bundles all static data from SQLite for the Explore Filters.
  FilterStaticDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filterStaticDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filterStaticDataHash();

  @$internal
  @override
  $FutureProviderElement<FilterStaticData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FilterStaticData> create(Ref ref) {
    return filterStaticData(ref);
  }
}

String _$filterStaticDataHash() => r'9e64d97a0e449e20e746bc7cac84f3787ce581a9';
