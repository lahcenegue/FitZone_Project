// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subscriptionApiService)
final subscriptionApiServiceProvider = SubscriptionApiServiceProvider._();

final class SubscriptionApiServiceProvider
    extends
        $FunctionalProvider<
          SubscriptionApiService,
          SubscriptionApiService,
          SubscriptionApiService
        >
    with $Provider<SubscriptionApiService> {
  SubscriptionApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionApiServiceHash();

  @$internal
  @override
  $ProviderElement<SubscriptionApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionApiService create(Ref ref) {
    return subscriptionApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionApiService>(value),
    );
  }
}

String _$subscriptionApiServiceHash() =>
    r'3cf3ea0dfa45d32669f0825f06ce29da5e2a89b9';

/// Fetches and caches the user's subscriptions.

@ProviderFor(mySubscriptions)
final mySubscriptionsProvider = MySubscriptionsProvider._();

/// Fetches and caches the user's subscriptions.

final class MySubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SubscriptionModel>>,
          List<SubscriptionModel>,
          FutureOr<List<SubscriptionModel>>
        >
    with
        $FutureModifier<List<SubscriptionModel>>,
        $FutureProvider<List<SubscriptionModel>> {
  /// Fetches and caches the user's subscriptions.
  MySubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySubscriptionsHash();

  @$internal
  @override
  $FutureProviderElement<List<SubscriptionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SubscriptionModel>> create(Ref ref) {
    return mySubscriptions(ref);
  }
}

String _$mySubscriptionsHash() => r'2a35cfe7c52883d2c94bc1737d1426aaf1536ef9';
