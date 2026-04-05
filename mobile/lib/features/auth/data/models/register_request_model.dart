/// Represents the data required to register a new user.
class RegisterRequestModel {
  final String email;
  final String password;
  final String fullName;
  final String gender;
  final String city;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.fullName,
    required this.gender,
    required this.city,
  });

  /// Converts the model to a JSON map for the API request.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'gender': gender,
      'city': city,
    };
  }
}
