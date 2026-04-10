import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/complete_profile_request_model.dart';
import 'auth_provider.dart';

part 'complete_profile_form_provider.g.dart';

class CompleteProfileFormState {
  final String phoneNumber;
  final String? realFaceImagePath;
  final String? idCardImagePath;
  final String address;
  final double? lat;
  final double? lng;

  final String? phoneError;
  final String? formError;
  final bool isFetchingLocation;

  CompleteProfileFormState({
    this.phoneNumber = '',
    this.realFaceImagePath,
    this.idCardImagePath,
    this.address = '',
    this.lat,
    this.lng,
    this.phoneError,
    this.formError,
    this.isFetchingLocation = false,
  });

  bool get isValid =>
      phoneNumber.isNotEmpty &&
      phoneError == null &&
      realFaceImagePath != null &&
      idCardImagePath != null;

  CompleteProfileFormState copyWith({
    String? phoneNumber,
    String? realFaceImagePath,
    String? idCardImagePath,
    String? address,
    double? lat,
    double? lng,
    String? phoneError,
    bool clearPhoneError = false,
    String? formError,
    bool clearFormError = false,
    bool? isFetchingLocation,
  }) {
    return CompleteProfileFormState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      realFaceImagePath: realFaceImagePath ?? this.realFaceImagePath,
      idCardImagePath: idCardImagePath ?? this.idCardImagePath,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      formError: clearFormError ? null : (formError ?? this.formError),
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
    );
  }
}

@riverpod
class CompleteProfileForm extends _$CompleteProfileForm {
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger('CompleteProfileForm');

  @override
  CompleteProfileFormState build() {
    final locationState = ref.read(userLocationProvider);
    // ARCHITECTURE FIX: Read user directly to act as Single Source of Truth
    final user = ref.read(authControllerProvider).value;
    final bool hasLocation = locationState.location != null;

    // Only fetch address if the user hasn't already saved one
    if (hasLocation && (user?.address == null || user!.address!.isEmpty)) {
      Future.microtask(() {
        _getAddressFromLatLng(
          locationState.location!.latitude,
          locationState.location!.longitude,
        );
      });
    }

    return CompleteProfileFormState(
      phoneNumber: user?.phoneNumber ?? '',
      address: user?.address ?? '',
      lat: user?.lat ?? locationState.location?.latitude,
      lng: user?.lng ?? locationState.location?.longitude,
      isFetchingLocation:
          hasLocation && (user?.address == null || user!.address!.isEmpty),
    );
  }

  void updatePhone(String value, AppLocalizations l10n) {
    String? error;
    // ARCHITECTURE FIX: Use centralized AppValidators
    if (value.isEmpty || !AppValidators.phoneRegex.hasMatch(value)) {
      error = l10n.invalidPhoneNumber;
    }
    state = state.copyWith(
      phoneNumber: value,
      phoneError: error,
      clearPhoneError: error == null,
      clearFormError: true,
    );
  }

  void updateAddress(String value) {
    state = state.copyWith(address: value);
  }

  Future<void> pickIdCardImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      state = state.copyWith(idCardImagePath: image.path, clearFormError: true);
    }
  }

  Future<void> pickFaceImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      state = state.copyWith(
        realFaceImagePath: image.path,
        clearFormError: true,
      );
    }
  }

  Future<void> refreshLocation() async {
    state = state.copyWith(isFetchingLocation: true);

    await ref.read(userLocationProvider.notifier).fetchLocation();
    final locationState = ref.read(userLocationProvider);

    if (locationState.location != null) {
      final lat = locationState.location!.latitude;
      final lng = locationState.location!.longitude;

      state = state.copyWith(lat: lat, lng: lng);
      await _getAddressFromLatLng(lat, lng);
    } else {
      state = state.copyWith(isFetchingLocation: false);
    }
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

  bool validateAll(AppLocalizations l10n) {
    updatePhone(state.phoneNumber, l10n);
    if (state.idCardImagePath == null || state.realFaceImagePath == null) {
      state = state.copyWith(formError: l10n.imagesRequiredError);
      return false;
    }
    return state.isValid;
  }

  CompleteProfileRequestModel toRequestModel() {
    return CompleteProfileRequestModel(
      phoneNumber: state.phoneNumber,
      realFaceImagePath: state.realFaceImagePath!,
      idCardImagePath: state.idCardImagePath!,
      address: state.address,
      lat: state.lat,
      lng: state.lng,
    );
  }
}
