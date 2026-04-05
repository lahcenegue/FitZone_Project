import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/utils/app_validators.dart';
import '../../data/models/register_request_model.dart';

part 'register_form_provider.g.dart';

/// Represents the current state of the registration form, including localized validation errors.
class RegisterFormState {
  final String fullName;
  final String email;
  final String password;
  final String? gender;
  final String? cityId;

  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? genderError;
  final String? cityError;

  RegisterFormState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.gender,
    this.cityId,
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.genderError,
    this.cityError,
  });

  /// Computed property to check if the entire form is valid.
  bool get isValid =>
      fullName.isNotEmpty &&
      fullNameError == null &&
      email.isNotEmpty &&
      emailError == null &&
      password.isNotEmpty &&
      passwordError == null &&
      gender != null &&
      genderError == null &&
      cityId != null &&
      cityError == null;

  RegisterFormState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? gender,
    String? cityId,
    String? fullNameError,
    bool clearFullNameError = false,
    String? emailError,
    bool clearEmailError = false,
    String? passwordError,
    bool clearPasswordError = false,
    String? genderError,
    bool clearGenderError = false,
    String? cityError,
    bool clearCityError = false,
  }) {
    return RegisterFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      cityId: cityId ?? this.cityId,
      fullNameError: clearFullNameError
          ? null
          : (fullNameError ?? this.fullNameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      genderError: clearGenderError ? null : (genderError ?? this.genderError),
      cityError: clearCityError ? null : (cityError ?? this.cityError),
    );
  }
}

/// Manages the state and localized validation logic of the registration form.
@riverpod
class RegisterForm extends _$RegisterForm {
  @override
  RegisterFormState build() {
    return RegisterFormState();
  }

  void updateFullName(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.nameRequired;
    } else if (!AppValidators.nameRegex.hasMatch(value)) {
      error = l10n.invalidName;
    }
    state = state.copyWith(
      fullName: value,
      fullNameError: error,
      clearFullNameError: error == null,
    );
  }

  void updateEmail(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.emailRequired;
    } else if (!AppValidators.emailRegex.hasMatch(value)) {
      error = l10n.invalidEmail;
    }
    state = state.copyWith(
      email: value,
      emailError: error,
      clearEmailError: error == null,
    );
  }

  void updatePassword(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.passwordRequired;
    } else if (!AppValidators.passwordRegex.hasMatch(value)) {
      error = l10n.invalidPassword;
    }
    state = state.copyWith(
      password: value,
      passwordError: error,
      clearPasswordError: error == null,
    );
  }

  void updateGender(String? value, AppLocalizations l10n) {
    String? error;
    if (value == null || value.isEmpty) {
      error = l10n.genderRequired;
    }
    state = state.copyWith(
      gender: value,
      genderError: error,
      clearGenderError: error == null,
    );
  }

  void updateCity(String? value, AppLocalizations l10n) {
    String? error;
    if (value == null || value.isEmpty) {
      error = l10n.cityRequired;
    }
    state = state.copyWith(
      cityId: value,
      cityError: error,
      clearCityError: error == null,
    );
  }

  /// Forces validation on all fields using the provided localizations.
  bool validateAll(AppLocalizations l10n) {
    updateFullName(state.fullName, l10n);
    updateEmail(state.email, l10n);
    updatePassword(state.password, l10n);
    updateGender(state.gender, l10n);
    updateCity(state.cityId, l10n);
    return state.isValid;
  }

  /// Converts the current valid state into a Request Model for the API.
  RegisterRequestModel toRequestModel() {
    return RegisterRequestModel(
      fullName: state.fullName,
      email: state.email,
      password: state.password,
      gender: state.gender!,
      city: state.cityId!,
    );
  }
}
