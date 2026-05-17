// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_profile_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompleteProfileForm)
final completeProfileFormProvider = CompleteProfileFormProvider._();

final class CompleteProfileFormProvider
    extends $NotifierProvider<CompleteProfileForm, CompleteProfileFormState> {
  CompleteProfileFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'completeProfileFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$completeProfileFormHash();

  @$internal
  @override
  CompleteProfileForm create() => CompleteProfileForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompleteProfileFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompleteProfileFormState>(value),
    );
  }
}

String _$completeProfileFormHash() =>
    r'c6d7abe5ca5ab72312b26f338b81bcc123a5a6c8';

abstract class _$CompleteProfileForm
    extends $Notifier<CompleteProfileFormState> {
  CompleteProfileFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CompleteProfileFormState, CompleteProfileFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompleteProfileFormState, CompleteProfileFormState>,
              CompleteProfileFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
