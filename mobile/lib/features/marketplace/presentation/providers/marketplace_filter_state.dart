import '../../../../core/config/app_constants.dart';

/// Holds the comprehensive state of all marketplace filters.
class MarketplaceFilterState {
  final String? query;
  final String? cityId;
  final double radiusKm;
  final String? sortBy;

  final String? gender;
  final double? minPrice;
  final double? maxPrice;
  final int? minDays;
  final int? minDiscount;

  const MarketplaceFilterState({
    this.query,
    this.cityId,
    this.radiusKm = AppConstants.maxdistamceKm,
    this.sortBy,
    this.gender,
    this.minPrice,
    this.maxPrice,
    this.minDays,
    this.minDiscount,
  });

  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (cityId != null && cityId!.isNotEmpty) count++;
    if (radiusKm < AppConstants.maxdistamceKm) count++;
    if (gender != null && gender!.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minDays != null && minDays! > 0) count++;
    if (minDiscount != null && minDiscount! > 0) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    return count;
  }

  MarketplaceFilterState copyWith({
    String? query,
    bool clearQuery = false,
    String? cityId,
    bool clearCity = false,
    double? radiusKm,
    String? sortBy,
    bool clearSortBy = false,
    String? gender,
    bool clearGender = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    int? minDays,
    bool clearMinDays = false,
    int? minDiscount,
    bool clearMinDiscount = false,
  }) {
    return MarketplaceFilterState(
      query: clearQuery ? null : (query ?? this.query),
      cityId: clearCity ? null : (cityId ?? this.cityId),
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      gender: clearGender ? null : (gender ?? this.gender),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minDays: clearMinDays ? null : (minDays ?? this.minDays),
      minDiscount: clearMinDiscount ? null : (minDiscount ?? this.minDiscount),
    );
  }
}
