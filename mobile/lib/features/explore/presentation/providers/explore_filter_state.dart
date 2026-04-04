import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines the four core service types available in the application.
enum ServiceCategory { gym, trainer, restaurant, equipment }

/// Holds the comprehensive state of all explore filters across all service categories.
class ExploreFilterState {
  final String? query;
  final String category;
  final String? cityId;
  final double radiusKm;
  final String? sortBy;
  final LatLngBounds? bounds;

  // --- Shared Filters ---
  final bool isOpen;
  final String? gender; // 'male', 'female', 'mixed'
  final double? maxPrice;

  // --- Type-Specific Array Filters (IDs) ---
  final List<int> selectedSports;
  final List<int> selectedAmenities;
  final List<int> selectedDietary;
  final List<int> selectedEquipmentCategories;

  const ExploreFilterState({
    this.query,
    this.category = 'gym',
    this.cityId,
    this.radiusKm = 50.0,
    this.sortBy,
    this.bounds,
    this.isOpen = false,
    this.gender,
    this.maxPrice,
    this.selectedSports = const [],
    this.selectedAmenities = const [],
    this.selectedDietary = const [],
    this.selectedEquipmentCategories = const [],
  });

  ExploreFilterState copyWith({
    String? query,
    String? category,
    String? cityId,
    double? radiusKm,
    String? sortBy,
    LatLngBounds? bounds,
    bool? isOpen,
    String? gender,
    double? maxPrice,
    List<int>? selectedSports,
    List<int>? selectedAmenities,
    List<int>? selectedDietary,
    List<int>? selectedEquipmentCategories,
  }) {
    return ExploreFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      cityId: cityId ?? this.cityId,
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: sortBy ?? this.sortBy,
      bounds: bounds ?? this.bounds,
      isOpen: isOpen ?? this.isOpen,
      gender: gender ?? this.gender,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedSports: selectedSports ?? this.selectedSports,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      selectedDietary: selectedDietary ?? this.selectedDietary,
      selectedEquipmentCategories:
          selectedEquipmentCategories ?? this.selectedEquipmentCategories,
    );
  }
}
