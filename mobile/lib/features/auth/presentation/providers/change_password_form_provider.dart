import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../l10n/app_localizations.dart';

part 'change_password_form_provider.g.dart';

class ChangePasswordFormState {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  final String? oldPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;

  ChangePasswordFormState({
    this.oldPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.oldPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
  });

  bool get isValid =>
      oldPassword.isNotEmpty &&
      oldPasswordError == null &&
      newPassword.isNotEmpty &&
      newPasswordError == null &&
      confirmPassword.isNotEmpty &&
      confirmPasswordError == null &&
      newPassword == confirmPassword;

  ChangePasswordFormState copyWith({
    String? oldPassword,
    String? newPassword,
    String? confirmPassword,
    String? oldPasswordError,
    bool clearOldPasswordError = false,
    String? newPasswordError,
    bool clearNewPasswordError = false,
    String? confirmPasswordError,
    bool clearConfirmPasswordError = false,
  }) {
    return ChangePasswordFormState(
      oldPassword: oldPassword ?? this.oldPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      oldPasswordError: clearOldPasswordError
          ? null
          : (oldPasswordError ?? this.oldPasswordError),
      newPasswordError: clearNewPasswordError
          ? null
          : (newPasswordError ?? this.newPasswordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
    );
  }
}

@riverpod
class ChangePasswordForm extends _$ChangePasswordForm {
  @override
  ChangePasswordFormState build() {
    return ChangePasswordFormState();
  }

  void updateOldPassword(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.oldPasswordRequired;
    }
    state = state.copyWith(
      oldPassword: value,
      oldPasswordError: error,
      clearOldPasswordError: error == null,
    );
  }

  void updateNewPassword(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.passwordRequiredError;
    } else if (!AppValidators.passwordRegex.hasMatch(value)) {
      error = l10n.invalidPassword;
    }

    // Also re-validate confirm password if it was already entered
    String? confirmError = state.confirmPasswordError;
    if (state.confirmPassword.isNotEmpty && value != state.confirmPassword) {
      confirmError = l10n.passwordsDoNotMatch;
    } else if (state.confirmPassword.isNotEmpty &&
        value == state.confirmPassword) {
      confirmError = null;
    }

    state = state.copyWith(
      newPassword: value,
      newPasswordError: error,
      clearNewPasswordError: error == null,
      confirmPasswordError: confirmError,
      clearConfirmPasswordError: confirmError == null,
    );
  }

  void updateConfirmPassword(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty) {
      error = l10n.passwordRequiredError;
    } else if (value != state.newPassword) {
      error = l10n.passwordsDoNotMatch;
    }
    state = state.copyWith(
      confirmPassword: value,
      confirmPasswordError: error,
      clearConfirmPasswordError: error == null,
    );
  }

  bool validateAll(AppLocalizations l10n) {
    updateOldPassword(state.oldPassword, l10n);
    updateNewPassword(state.newPassword, l10n);
    updateConfirmPassword(state.confirmPassword, l10n);
    return state.isValid;
  }
}
