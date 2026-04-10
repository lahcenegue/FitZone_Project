// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the state and localized validation logic of the registration form.

@ProviderFor(RegisterForm)
final registerFormProvider = RegisterFormProvider._();

/// Manages the state and localized validation logic of the registration form.
final class RegisterFormProvider
    extends $NotifierProvider<RegisterForm, RegisterFormState> {
  /// Manages the state and localized validation logic of the registration form.
  RegisterFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerFormHash();

  @$internal
  @override
  RegisterForm create() => RegisterForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterFormState>(value),
    );
  }
}

String _$registerFormHash() => r'55865d885095d38217e4cbda764217bb443d7d68';

/// Manages the state and localized validation logic of the registration form.

abstract class _$RegisterForm extends $Notifier<RegisterFormState> {
  RegisterFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RegisterFormState, RegisterFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterFormState, RegisterFormState>,
              RegisterFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
