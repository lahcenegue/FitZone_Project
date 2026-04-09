import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Holds the comprehensive state of all explore filters across all service categories.
class ExploreFilterState {
  final String? query;
  final String category;
  final String? cityId;
  final double radiusKm;
  final String? sortBy;
  final LatLngBounds? bounds;

  // Shared Filters
  final bool isOpen;
  final String? gender;
  final double? minPrice;
  final double? maxPrice;

  // Type-Specific Array Filters (IDs)
  final List<int> selectedSports;
  final List<int> selectedAmenities;
  final List<int> selectedDietary;
  final List<int> selectedEquipmentCategories;

  const ExploreFilterState({
    this.query,
    this.category = 'gym',
    this.cityId,
    this.radiusKm = 200.0,
    this.sortBy,
    this.bounds,
    this.isOpen = false,
    this.gender,
    this.minPrice,
    this.maxPrice,
    this.selectedSports = const [],
    this.selectedAmenities = const [],
    this.selectedDietary = const [],
    this.selectedEquipmentCategories = const [],
  });

  /// Returns the number of currently active filters
  int get activeFilterCount {
    int count = 0;
    if (cityId != null) count++;
    if (radiusKm < 200.0) count++;
    if (gender != null) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (isOpen) count++;
    if (selectedSports.isNotEmpty) count++;
    if (selectedAmenities.isNotEmpty) count++;
    if (selectedDietary.isNotEmpty) count++;
    if (selectedEquipmentCategories.isNotEmpty) count++;
    if (sortBy != null) count++;
    return count;
  }

  ExploreFilterState copyWith({
    String? query,
    String? category,
    String? cityId,
    double? radiusKm,
    String? sortBy,
    LatLngBounds? bounds,
    bool? isOpen,
    String? gender,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
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
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      selectedSports: selectedSports ?? this.selectedSports,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      selectedDietary: selectedDietary ?? this.selectedDietary,
      selectedEquipmentCategories:
          selectedEquipmentCategories ?? this.selectedEquipmentCategories,
    );
  }
}
