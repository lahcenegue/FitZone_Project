// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DeleteAccountForm)
final deleteAccountFormProvider = DeleteAccountFormProvider._();

final class DeleteAccountFormProvider
    extends $NotifierProvider<DeleteAccountForm, DeleteAccountFormState> {
  DeleteAccountFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountFormHash();

  @$internal
  @override
  DeleteAccountForm create() => DeleteAccountForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteAccountFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteAccountFormState>(value),
    );
  }
}

String _$deleteAccountFormHash() => r'6062010f9154a8b67ddb220802861f804b5ebb4a';

abstract class _$DeleteAccountForm extends $Notifier<DeleteAccountFormState> {
  DeleteAccountFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DeleteAccountFormState, DeleteAccountFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeleteAccountFormState, DeleteAccountFormState>,
              DeleteAccountFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
