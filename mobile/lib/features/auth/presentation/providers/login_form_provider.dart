import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';

part 'login_form_provider.g.dart';

class LoginFormState {
  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;

  LoginFormState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
  });

  bool get isValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;

  LoginFormState copyWith({
    String? email,
    String? password,
    String? emailError,
    bool clearEmailError = false,
    String? passwordError,
    bool clearPasswordError = false,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
    );
  }
}

@riverpod
class LoginForm extends _$LoginForm {
  @override
  LoginFormState build() {
    return LoginFormState();
  }

  void updateEmail(String value, AppLocalizations l10n) {
    String? error;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (value.isEmpty || !emailRegex.hasMatch(value)) {
      error = l10n.invalidEmailError;
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
      error = l10n.passwordRequiredError;
    }
    state = state.copyWith(
      password: value,
      passwordError: error,
      clearPasswordError: error == null,
    );
  }

  bool validateAll(AppLocalizations l10n) {
    updateEmail(state.email, l10n);
    updatePassword(state.password, l10n);
    return state.isValid;
  }
}
