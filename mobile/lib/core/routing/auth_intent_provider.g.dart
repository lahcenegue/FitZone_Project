// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_intent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authIntentService)
final authIntentServiceProvider = AuthIntentServiceProvider._();

final class AuthIntentServiceProvider
    extends
        $FunctionalProvider<
          AuthIntentService,
          AuthIntentService,
          AuthIntentService
        >
    with $Provider<AuthIntentService> {
  AuthIntentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authIntentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authIntentServiceHash();

  @$internal
  @override
  $ProviderElement<AuthIntentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthIntentService create(Ref ref) {
    return authIntentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthIntentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthIntentService>(value),
    );
  }
}

String _$authIntentServiceHash() => r'63870f30e16fda10695d2736c0bd150a3018ed60';
