import 'package:geocoding/geocoding.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/utils/app_validators.dart';
import '../../data/models/register_request_model.dart';

part 'register_form_provider.g.dart';

/// Represents the current state of the registration form, including localized validation errors.
class RegisterFormState {
  final String fullName;
  final String email;
  final String password;
  final String? gender;
  final String? city;
  final String phoneNumber;
  final String address;
  final double? lat;
  final double? lng;

  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? genderError;
  final String? cityError;
  final String? phoneError;
  final bool isFetchingLocation;

  RegisterFormState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.gender,
    this.city,
    this.phoneNumber = '',
    this.address = '',
    this.lat,
    this.lng,
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.genderError,
    this.cityError,
    this.phoneError,
    this.isFetchingLocation = false,
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
      city != null &&
      cityError == null &&
      phoneNumber.isNotEmpty &&
      phoneError == null &&
      address.isNotEmpty &&
      lat != null &&
      lng != null;

  RegisterFormState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? gender,
    String? city,
    String? phoneNumber,
    String? address,
    double? lat,
    double? lng,
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
    String? phoneError,
    bool clearPhoneError = false,
    bool? isFetchingLocation,
  }) {
    return RegisterFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      fullNameError: clearFullNameError
          ? null
          : (fullNameError ?? this.fullNameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      genderError: clearGenderError ? null : (genderError ?? this.genderError),
      cityError: clearCityError ? null : (cityError ?? this.cityError),
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
    );
  }
}

/// Manages the state and localized validation logic of the registration form.
@riverpod
class RegisterForm extends _$RegisterForm {
  final Logger _logger = Logger('RegisterForm');

  @override
  RegisterFormState build() {
    final locationState = ref.read(userLocationProvider);
    final bool hasLocation = locationState.location != null;

    if (hasLocation) {
      Future.microtask(() {
        _getAddressFromLatLng(
          locationState.location!.latitude,
          locationState.location!.longitude,
        );
      });
    }

    return RegisterFormState(
      lat: locationState.location?.latitude,
      lng: locationState.location?.longitude,
      isFetchingLocation: hasLocation,
    );
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
      city: value,
      cityError: error,
      clearCityError: error == null,
    );
  }

  void updatePhone(String value, AppLocalizations l10n) {
    String? error;
    if (value.isEmpty || !AppValidators.phoneRegex.hasMatch(value)) {
      error = l10n.invalidPhoneNumber;
    }
    state = state.copyWith(
      phoneNumber: value,
      phoneError: error,
      clearPhoneError: error == null,
    );
  }

  void updateAddress(String address, double lat, double lng) {
    state = state.copyWith(address: address, lat: lat, lng: lng);
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressParts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (addressParts.isEmpty && place.street != null) {
          addressParts.add(place.street!);
        }

        final String readableAddress = addressParts.join(', ');

        state = state.copyWith(
          address: readableAddress,
          isFetchingLocation: false,
        );
        _logger.info('Reverse Geocoding successful: $readableAddress');
      }
    } catch (e) {
      _logger.warning('Failed to reverse geocode coordinates', e);
      state = state.copyWith(isFetchingLocation: false);
    }
  }

  /// Forces validation on all fields using the provided localizations.
  bool validateAll(AppLocalizations l10n) {
    updateFullName(state.fullName, l10n);
    updateEmail(state.email, l10n);
    updatePassword(state.password, l10n);
    updateGender(state.gender, l10n);
    updateCity(state.city, l10n);
    updatePhone(state.phoneNumber, l10n);
    return state.isValid;
  }

  /// Converts the current valid state into a Request Model for the API.
  RegisterRequestModel toRequestModel() {
    return RegisterRequestModel(
      fullName: state.fullName,
      email: state.email,
      password: state.password,
      gender: state.gender!,
      city: state.city!,
      phoneNumber: state.phoneNumber,
      address: state.address,
      lat: state.lat!,
      lng: state.lng!,
    );
  }
}
