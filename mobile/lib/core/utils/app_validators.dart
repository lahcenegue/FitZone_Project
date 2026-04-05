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
}
