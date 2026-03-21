import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreFilterState {
  final String? query;
  final String type;
  final String? gender;
  final bool isOpen;
  final double? maxPrice;
  final double radiusKm; // حقل مخصص للمسافة
  final List<String> selectedSports;
  final List<String> selectedAmenities;
  final String? sortBy;
  final LatLngBounds? bounds;

  const ExploreFilterState({
    this.query,
    this.type = 'gym',
    this.gender,
    this.isOpen = false,
    this.maxPrice,
    this.radiusKm = 50.0, // القيمة الافتراضية للمسافة
    this.selectedSports = const [],
    this.selectedAmenities = const [],
    this.sortBy,
    this.bounds,
  });

  ExploreFilterState copyWith({
    String? query,
    String? type,
    String? gender,
    bool? isOpen,
    double? maxPrice,
    double? radiusKm,
    List<String>? selectedSports,
    List<String>? selectedAmenities,
    String? sortBy,
    LatLngBounds? bounds,
  }) {
    return ExploreFilterState(
      query: query ?? this.query,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      isOpen: isOpen ?? this.isOpen,
      maxPrice: maxPrice ?? this.maxPrice,
      radiusKm: radiusKm ?? this.radiusKm,
      selectedSports: selectedSports ?? this.selectedSports,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      sortBy: sortBy ?? this.sortBy,
      bounds: bounds ?? this.bounds,
    );
  }
}
