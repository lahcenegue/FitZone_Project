// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches and bundles all static data from SQLite.

@ProviderFor(appStaticData)
final appStaticDataProvider = AppStaticDataProvider._();

/// Fetches and bundles all static data from SQLite.

final class AppStaticDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppStaticData>,
          AppStaticData,
          FutureOr<AppStaticData>
        >
    with $FutureModifier<AppStaticData>, $FutureProvider<AppStaticData> {
  /// Fetches and bundles all static data from SQLite.
  AppStaticDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStaticDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStaticDataHash();

  @$internal
  @override
  $FutureProviderElement<AppStaticData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppStaticData> create(Ref ref) {
    return appStaticData(ref);
  }
}

String _$appStaticDataHash() => r'05a00d5cc4f67ca0867a659b335a82d0a3a29cae';
