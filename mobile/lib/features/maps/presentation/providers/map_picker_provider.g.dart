// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls the logic and state mutations for the Hybrid Map Picker.

@ProviderFor(MapPickerController)
final mapPickerControllerProvider = MapPickerControllerProvider._();

/// Controls the logic and state mutations for the Hybrid Map Picker.
final class MapPickerControllerProvider
    extends $NotifierProvider<MapPickerController, MapPickerState> {
  /// Controls the logic and state mutations for the Hybrid Map Picker.
  MapPickerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapPickerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapPickerControllerHash();

  @$internal
  @override
  MapPickerController create() => MapPickerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapPickerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapPickerState>(value),
    );
  }
}

String _$mapPickerControllerHash() =>
    r'28c46122b340a52fd3771a805fb4ddeeedf9668b';

/// Controls the logic and state mutations for the Hybrid Map Picker.

abstract class _$MapPickerController extends $Notifier<MapPickerState> {
  MapPickerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MapPickerState, MapPickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapPickerState, MapPickerState>,
              MapPickerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
