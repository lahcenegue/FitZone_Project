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
    this.category = 'gym', // Default category
    this.cityId,
    this.radiusKm = 200.0, // Default radius
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
  /// (Does not count 'category' or 'bounds' as user-selected filters for the badge)
  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (cityId != null && cityId!.isNotEmpty) count++;
    if (radiusKm < 200.0) count++; // Only counts if restricted from default
    if (gender != null && gender!.isNotEmpty) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (isOpen) count++;
    if (selectedSports.isNotEmpty) count++;
    if (selectedAmenities.isNotEmpty) count++;
    if (selectedDietary.isNotEmpty) count++;
    if (selectedEquipmentCategories.isNotEmpty) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    return count;
  }

  /// Creates a new state with updated fields.
  /// ARCHITECTURE FIX: Added clear flags for all nullable fields to ensure precise resetting.
  ExploreFilterState copyWith({
    String? query,
    bool clearQuery = false,
    String? category,
    String? cityId,
    bool clearCity = false,
    double? radiusKm,
    String? sortBy,
    bool clearSortBy = false,
    LatLngBounds? bounds,
    bool clearBounds = false,
    bool? isOpen,
    String? gender,
    bool clearGender = false,
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
      query: clearQuery ? null : (query ?? this.query),
      category: category ?? this.category,
      cityId: clearCity ? null : (cityId ?? this.cityId),
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      bounds: clearBounds ? null : (bounds ?? this.bounds),
      isOpen: isOpen ?? this.isOpen,
      gender: clearGender ? null : (gender ?? this.gender),
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
