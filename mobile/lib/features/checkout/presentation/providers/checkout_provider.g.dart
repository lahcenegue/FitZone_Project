// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkoutApiService)
final checkoutApiServiceProvider = CheckoutApiServiceProvider._();

final class CheckoutApiServiceProvider
    extends
        $FunctionalProvider<
          CheckoutApiService,
          CheckoutApiService,
          CheckoutApiService
        >
    with $Provider<CheckoutApiService> {
  CheckoutApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutApiServiceHash();

  @$internal
  @override
  $ProviderElement<CheckoutApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckoutApiService create(Ref ref) {
    return checkoutApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutApiService>(value),
    );
  }
}

String _$checkoutApiServiceHash() =>
    r'5bf28f3073783f9ead5fb98804069ca5bf6a4efa';

@ProviderFor(CheckoutController)
final checkoutControllerProvider = CheckoutControllerFamily._();

final class CheckoutControllerProvider
    extends $NotifierProvider<CheckoutController, CheckoutState> {
  CheckoutControllerProvider._({
    required CheckoutControllerFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'checkoutControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkoutControllerHash();

  @override
  String toString() {
    return r'checkoutControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CheckoutController create() => CheckoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckoutState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CheckoutControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkoutControllerHash() =>
    r'd01c15b46947d8e4da27646f9bd3b8138835b618';

final class CheckoutControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CheckoutController,
          CheckoutState,
          CheckoutState,
          CheckoutState,
          (String, int)
        > {
  CheckoutControllerFamily._()
    : super(
        retry: null,
        name: r'checkoutControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CheckoutControllerProvider call(String itemType, int itemId) =>
      CheckoutControllerProvider._(argument: (itemType, itemId), from: this);

  @override
  String toString() => r'checkoutControllerProvider';
}

abstract class _$CheckoutController extends $Notifier<CheckoutState> {
  late final _$args = ref.$arg as (String, int);
  String get itemType => _$args.$1;
  int get itemId => _$args.$2;

  CheckoutState build(String itemType, int itemId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CheckoutState, CheckoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CheckoutState, CheckoutState>,
              CheckoutState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
