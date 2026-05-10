import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/app_constants.dart';

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
  final double? maxPrice; // RESTORED: Max price for RangeSlider
  final String? crowdLevel;

  // Type-Specific Array Filters (IDs)
  final List<int> selectedSports;
  final List<int> selectedAmenities;
  final List<int> selectedDietary;
  final List<int> selectedEquipmentCategories;

  const ExploreFilterState({
    this.query,
    this.category = 'gym',
    this.cityId,
    this.radiusKm = AppConstants.maxdistamceKm,
    this.sortBy,
    this.bounds,
    this.isOpen = false,
    this.gender,
    this.minPrice,
    this.maxPrice,
    this.crowdLevel,
    this.selectedSports = const [],
    this.selectedAmenities = const [],
    this.selectedDietary = const [],
    this.selectedEquipmentCategories = const [],
  });

  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (cityId != null && cityId!.isNotEmpty) count++;
    if (radiusKm < AppConstants.maxdistamceKm) count++;
    if (gender != null && gender!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (crowdLevel != null && crowdLevel!.isNotEmpty) count++;
    if (isOpen) count++;
    if (selectedSports.isNotEmpty) count++;
    if (selectedAmenities.isNotEmpty) count++;
    if (selectedDietary.isNotEmpty) count++;
    if (selectedEquipmentCategories.isNotEmpty) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    return count;
  }

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
    String? crowdLevel,
    bool clearCrowdLevel = false,
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
      crowdLevel: clearCrowdLevel ? null : (crowdLevel ?? this.crowdLevel),
      selectedSports: selectedSports ?? this.selectedSports,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
      selectedDietary: selectedDietary ?? this.selectedDietary,
      selectedEquipmentCategories:
          selectedEquipmentCategories ?? this.selectedEquipmentCategories,
    );
  }
}
