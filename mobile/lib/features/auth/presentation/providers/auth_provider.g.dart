// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the AuthApiService instance with the globally configured Dio client.

@ProviderFor(authApiService)
final authApiServiceProvider = AuthApiServiceProvider._();

/// Provides the AuthApiService instance with the globally configured Dio client.

final class AuthApiServiceProvider
    extends $FunctionalProvider<AuthApiService, AuthApiService, AuthApiService>
    with $Provider<AuthApiService> {
  /// Provides the AuthApiService instance with the globally configured Dio client.
  AuthApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authApiServiceHash();

  @$internal
  @override
  $ProviderElement<AuthApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthApiService create(Ref ref) {
    return authApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthApiService>(value),
    );
  }
}

String _$authApiServiceHash() => r'2def2e7843dae96b4c7e00bc740d97dcd217ae22';

/// Manages the authentication state and operations.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Manages the authentication state and operations.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AsyncValue<UserModel?>> {
  /// Manages the authentication state and operations.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<UserModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<UserModel?>>(value),
    );
  }
}

String _$authControllerHash() => r'071c8943b31503252353fc5ff5c2203420b5d67c';

/// Manages the authentication state and operations.

abstract class _$AuthController extends $Notifier<AsyncValue<UserModel?>> {
  AsyncValue<UserModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UserModel?>, AsyncValue<UserModel?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserModel?>, AsyncValue<UserModel?>>,
              AsyncValue<UserModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
