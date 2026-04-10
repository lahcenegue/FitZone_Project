import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../l10n/app_localizations.dart';

part 'delete_account_form_provider.g.dart';

class DeleteAccountFormState {
  final String password;
  final String? passwordError;

  DeleteAccountFormState({this.password = '', this.passwordError});

  bool get isValid => password.isNotEmpty && passwordError == null;

  DeleteAccountFormState copyWith({
    String? password,
    String? passwordError,
    bool clearPasswordError = false,
  }) {
    return DeleteAccountFormState(
      password: password ?? this.password,
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
    );
  }
}

@riverpod
class DeleteAccountForm extends _$DeleteAccountForm {
  @override
  DeleteAccountFormState build() {
    return DeleteAccountFormState();
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
    updatePassword(state.password, l10n);
    return state.isValid;
  }
}
