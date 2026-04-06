import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/config/app_constants.dart';
import '../../data/services/places_api_service.dart';

part 'map_picker_provider.g.dart';

/// Holds the complete state of the Map Picker screen.
class MapPickerState {
  final LatLng currentCenter;
  final String currentAddress;
  final bool isFetchingAddress;
  final List<Map<String, dynamic>> searchResults;
  final bool isSearching;

  MapPickerState({
    required this.currentCenter,
    this.currentAddress = '',
    this.isFetchingAddress = false,
    this.searchResults = const [],
    this.isSearching = false,
  });

  MapPickerState copyWith({
    LatLng? currentCenter,
    String? currentAddress,
    bool? isFetchingAddress,
    List<Map<String, dynamic>>? searchResults,
    bool? isSearching,
  }) {
    return MapPickerState(
      currentCenter: currentCenter ?? this.currentCenter,
      currentAddress: currentAddress ?? this.currentAddress,
      isFetchingAddress: isFetchingAddress ?? this.isFetchingAddress,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Controls the logic and state mutations for the Hybrid Map Picker.
@riverpod
class MapPickerController extends _$MapPickerController {
  final Logger _logger = Logger('MapPickerController');

  // Generates a unique session token for Google Places Autocomplete billing
  String _sessionToken = const Uuid().v4();

  @override
  MapPickerState build() {
    final locationState = ref.read(userLocationProvider);

    // Initialize map center to user's real location or a fallback constant (Riyadh)
    final initialLatLng = locationState.location != null
        ? LatLng(
            locationState.location!.latitude,
            locationState.location!.longitude,
          )
        : AppConstants.defaultMapCenter;

    // Trigger reverse geocoding asynchronously after the initial build completes
    Future.microtask(() => _fetchAddressFromLatLng(initialLatLng));

    return MapPickerState(
      currentCenter: initialLatLng,
      isFetchingAddress: true,
    );
  }

  /// Called continuously while the user drags the map.
  void onCameraMove(CameraPosition position) {
    state = state.copyWith(
      currentCenter: position.target,
      isFetchingAddress: true,
      currentAddress:
          '', // Clear address while moving to indicate a pending state
    );
  }

  /// Called when the user stops dragging the map.
  Future<void> onCameraIdle() async {
    await _fetchAddressFromLatLng(state.currentCenter);
  }

  /// Converts map coordinates (Lat/Lng) into a human-readable street/city address.
  Future<void> _fetchAddressFromLatLng(LatLng target) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> addressParts = [];

        // Build a clean, readable address structure
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          addressParts.add(place.locality!);
        if (addressParts.isEmpty && place.street != null)
          addressParts.add(place.street!);

        state = state.copyWith(
          currentAddress: addressParts.join(', '),
          isFetchingAddress: false,
        );
      } else {
        state = state.copyWith(
          isFetchingAddress: false,
          currentAddress: 'Unknown Location',
        );
      }
    } catch (e) {
      _logger.warning(
        'Geocoding failed for coordinates: ${target.latitude}, ${target.longitude}',
        e,
      );
      state = state.copyWith(
        isFetchingAddress: false,
        currentAddress: 'Unknown Location',
      );
    }
  }

  /// Sends a query to Google Places Autocomplete.
  Future<void> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    state = state.copyWith(isSearching: true);
    final placesService = ref.read(placesApiServiceProvider);
    final results = await placesService.getAutocompleteSuggestions(
      query,
      _sessionToken,
    );

    state = state.copyWith(searchResults: results, isSearching: false);
  }

  /// Retrieves exact coordinates for a tapped search suggestion and updates the map.
  Future<LatLng?> getPlaceDetailsAndMove(String placeId) async {
    state = state.copyWith(isSearching: true);
    final placesService = ref.read(placesApiServiceProvider);
    final details = await placesService.getPlaceDetails(placeId, _sessionToken);

    // Crucial: Reset the session token after a successful selection to close the billing cycle
    _sessionToken = const Uuid().v4();
    clearSearch();

    if (details != null && details['geometry'] != null) {
      final location = details['geometry']['location'];
      final target = LatLng(
        location['lat'] as double,
        location['lng'] as double,
      );

      state = state.copyWith(
        currentCenter: target,
        currentAddress: details['name'] ?? details['formatted_address'] ?? '',
        isSearching: false,
        isFetchingAddress: false,
      );
      return target;
    }

    state = state.copyWith(isSearching: false);
    return null;
  }

  /// Clears the autocomplete search results from the UI.
  void clearSearch() {
    state = state.copyWith(searchResults: [], isSearching: false);
  }
}
