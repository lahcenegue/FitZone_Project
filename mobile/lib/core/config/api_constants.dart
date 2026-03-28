/// Centralized API endpoints and configuration.
class ApiConstants {
  ApiConstants._();

  // Base URL (10.0.2.2 is localhost for Android Emulators)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Map Discovery
  static const String mapDiscover = '/providers/discover/';

  // Branch Details
  static const String gymBranchDetails = '/gyms/branches/';

  // Bootstrapping Endpoints
  static const String initConfig = '/init/';
  static const String cities = '/cities/';
  static const String sports = '/gyms/sports/';
  static const String amenities = '/gyms/amenities/';
}
