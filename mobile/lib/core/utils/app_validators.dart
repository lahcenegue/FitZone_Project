import '../../l10n/app_localizations.dart';

/// Centralized regular expressions and validation logic.
class AppValidators {
  AppValidators._();

  /// Validates standard email format.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  /// Minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number, and 1 special character.
  static final RegExp passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Accepts English and Arabic letters, and spaces only. Min 3, Max 50.
  static final RegExp nameRegex = RegExp(r'^[\u0600-\u06FFa-zA-Z\s]{3,50}$');

  /// Saudi phone number format: starts with 05 and has exactly 10 digits.
  static final RegExp phoneRegex = RegExp(r'^05[0-9]{8}$');

  /// Validates financial withdrawal amounts.
  static String? validateWithdrawalAmount(
    String? value,
    double maxAmount,
    double minAmount,
    AppLocalizations l10n,
  ) {
    if (value == null || value.trim().isEmpty) {
      return l10n.amountRequired;
    }
    final double? parsedAmount = double.tryParse(value.trim());
    if (parsedAmount == null) {
      return l10n.errorValidation;
    }
    if (parsedAmount < minAmount) {
      return l10n.minWithdrawal(minAmount.toStringAsFixed(0));
    }
    if (parsedAmount > maxAmount) {
      return l10n.insufficientBalance;
    }
    return null;
  }
}
