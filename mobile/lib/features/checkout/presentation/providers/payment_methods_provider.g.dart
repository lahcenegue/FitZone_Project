// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_methods_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of available payment methods.
/// Currently hardcoded, but structured to easily fetch from an API later.

@ProviderFor(paymentMethods)
final paymentMethodsProvider = PaymentMethodsProvider._();

/// Provides the list of available payment methods.
/// Currently hardcoded, but structured to easily fetch from an API later.

final class PaymentMethodsProvider
    extends
        $FunctionalProvider<
          List<PaymentMethodModel>,
          List<PaymentMethodModel>,
          List<PaymentMethodModel>
        >
    with $Provider<List<PaymentMethodModel>> {
  /// Provides the list of available payment methods.
  /// Currently hardcoded, but structured to easily fetch from an API later.
  PaymentMethodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentMethodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentMethodsHash();

  @$internal
  @override
  $ProviderElement<List<PaymentMethodModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<PaymentMethodModel> create(Ref ref) {
    return paymentMethods(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PaymentMethodModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PaymentMethodModel>>(value),
    );
  }
}

String _$paymentMethodsHash() => r'bbb46124c127f48076a5ff67aac4fe2c9fa4e307';
