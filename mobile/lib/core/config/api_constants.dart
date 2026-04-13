/// Centralized API endpoints and configuration.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // --- Auth & User Profile ---
  static const String register = '/users/register/';
  static const String verifyEmail = '/users/verify-email/';
  static const String resendVerification = '/users/resend-verification/';
  static const String login = '/users/login/';
  static const String completeProfile = '/users/profile/complete/';
  static const String requestPasswordReset = '/users/password-reset/request/';
  static const String confirmPasswordReset = '/users/password-reset/confirm/';

  // --- Security & Profile Endpoints ---
  static const String refreshToken = '/users/token/refresh/';
  static const String logout = '/users/logout/';
  static const String changePassword = '/users/profile/change-password/';
  static const String updateAvatar = '/users/profile/avatar/';
  static const String updateProfile = '/users/profile/update/';
  static const String deleteAccount = '/users/profile/delete/';

  // --- Subscriptions & Checkout (NEW) ---
  static const String checkout = '/gyms/checkout/';
  static const String mySubscriptions = '/users/my-subscriptions/';

  // --- Map Discovery ---
  static const String mapDiscover = '/providers/discover/';

  // --- Branch Details ---
  static const String gymBranchDetails = '/gyms/branches/';

  // --- Bootstrapping Endpoints ---
  static const String initConfig = '/init/';
  static const String serviceTypes = '/service-types/';
  static const String cities = '/cities/';

  // --- Filters For Gym ---
  static const String sports = '/gyms/sports/';
  static const String amenities = '/gyms/amenities/';
}
