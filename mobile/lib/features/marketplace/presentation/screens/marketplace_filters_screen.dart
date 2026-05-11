import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_data_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/marketplace_filter_state.dart';
import '../providers/marketplace_providers.dart';

class MarketplaceFiltersScreen extends ConsumerStatefulWidget {
  const MarketplaceFiltersScreen({super.key});

  @override
  ConsumerState<MarketplaceFiltersScreen> createState() =>
      _MarketplaceFiltersScreenState();
}

class _MarketplaceFiltersScreenState
    extends ConsumerState<MarketplaceFiltersScreen> {
  late MarketplaceFilterState _localState;
  static const double _maxAllowedPrice = 3000.0;
  static const double _maxDays = 365.0;

  @override
  void initState() {
    super.initState();
    _localState = ref.read(marketplaceFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final staticDataAsync = ref.watch(appStaticDataProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(l10n, colors),
      body: staticDataAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (error, stack) => Center(
          child: Text(
            'Error loading data',
            style: TextStyle(color: colors.error),
          ),
        ),
        data: (staticData) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingLarge,
                    vertical: Dimensions.spacingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(l10n.filters, colors),
                      _buildGeographyCard(colors, l10n, staticData.cities),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.dealSummary, colors),
                      _buildFinancialFiltersCard(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.gender, colors),
                      _buildGenderCard(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.sortBy, colors),
                      _buildSortCard(colors, l10n),

                      SizedBox(height: Dimensions.spacingExtraLarge * 3),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(l10n, colors),
            ],
          );
        },
      ),
    );
  }

  // --- Filter Cards ---

  Widget _buildGeographyCard(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> cities,
  ) {
    return _buildPremiumCard(
      colors: colors,
      child: Column(
        children: [
          _buildCitySelector(colors, l10n, cities),
          _buildDivider(colors),
          _buildRadiusSlider(colors, l10n),
        ],
      ),
    );
  }

  Widget _buildFinancialFiltersCard(AppColors colors, AppLocalizations l10n) {
    return _buildPremiumCard(
      colors: colors,
      child: Column(
        children: [
          _buildPriceRangeSlider(colors, l10n),
          _buildDivider(colors),
          _buildDaysLeftSlider(colors, l10n),
          _buildDivider(colors),
          _buildMinDiscountSlider(colors, l10n),
        ],
      ),
    );
  }

  Widget _buildGenderCard(AppColors colors, AppLocalizations l10n) {
    return _buildSegmentedOptionsCard(
      colors: colors,
      // ARCHITECTURE FIX: Removed 'mixed' option per user request
      options: {'male': l10n.genderMale, 'female': l10n.genderFemale},
      currentValue: _localState.gender,
      onChanged: (val) => setState(() {
        _localState = _localState.gender == val
            ? _localState.copyWith(clearGender: true)
            : _localState.copyWith(gender: val);
      }),
    );
  }

  Widget _buildSortCard(AppColors colors, AppLocalizations l10n) {
    return _buildSegmentedOptionsCard(
      colors: colors,
      options: {
        'distance': l10n.distance,
        '-discount': l10n.highestDiscount,
        'price_asc': l10n.lowestPrice,
      },
      currentValue: _localState.sortBy ?? 'distance',
      onChanged: (val) => setState(() {
        _localState = _localState.copyWith(sortBy: val);
      }),
    );
  }

  // --- Premium Components ---

  Widget _buildPremiumCard({required AppColors colors, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSegmentedOptionsCard({
    required AppColors colors,
    required Map<String, String> options,
    required String? currentValue,
    required Function(String) onChanged,
  }) {
    return _buildPremiumCard(
      colors: colors,
      child: Padding(
        padding: EdgeInsets.all(Dimensions.spacingMedium),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.iconGrey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
          child: Row(
            children: options.entries.map((entry) {
              final isSelected = currentValue == entry.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: Dimensions.spacingMedium,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colors.shadow.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected
                            ? colors.primary
                            : colors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: Dimensions.fontBodyMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- Inputs ---

  Widget _buildCitySelector(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> cities,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingSmall,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _localState.cityId,
          dropdownColor: colors.surface,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.iconGrey,
            size: Dimensions.iconMedium,
          ),
          hint: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.spacingSmall),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: colors.primary,
                  size: Dimensions.iconMedium,
                ),
              ),
              SizedBox(width: Dimensions.spacingMedium),
              Text(
                l10n.allRegions,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimensions.spacingSmall),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      color: colors.primary,
                      size: Dimensions.iconMedium,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingMedium),
                  Text(l10n.allRegions),
                ],
              ),
            ),
            ...cities.map(
              (city) => DropdownMenuItem<String>(
                value: city['id'].toString(),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Dimensions.spacingSmall),
                      decoration: BoxDecoration(
                        color: colors.iconGrey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: colors.iconGrey,
                        size: Dimensions.iconMedium,
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingMedium),
                    Text(city['name'].toString()),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(
              cityId: val,
              clearCity: val == null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSlider(AppColors colors, AppLocalizations l10n) {
    final bool isUnlimited = _localState.radiusKm >= 200.0;
    return _buildSliderSection(
      colors: colors,
      title: l10n.distance,
      valueText: isUnlimited
          ? l10n.anyDistance
          : "${_localState.radiusKm.round()} ${l10n.km}",
      slider: Slider(
        value: _localState.radiusKm,
        min: 1.0,
        max: 200.0,
        onChanged: (val) =>
            setState(() => _localState = _localState.copyWith(radiusKm: val)),
      ),
    );
  }

  Widget _buildDaysLeftSlider(AppColors colors, AppLocalizations l10n) {
    final int currentVal = _localState.minDays ?? 0;
    return _buildSliderSection(
      colors: colors,
      title: l10n.minDaysLeft,
      valueText: currentVal == 0 ? l10n.all : "+$currentVal ${l10n.daysLeft}",
      slider: Slider(
        value: currentVal.toDouble(),
        min: 0.0,
        max: _maxDays,
        // ARCHITECTURE FIX: Removed 'divisions' to allow continuous free-flowing selection of any day count
        onChanged: (val) => setState(
          () => _localState = _localState.copyWith(
            minDays: val.toInt(),
            clearMinDays: val == 0,
          ),
        ),
      ),
    );
  }

  Widget _buildMinDiscountSlider(AppColors colors, AppLocalizations l10n) {
    final int currentVal = _localState.minDiscount ?? 0;
    return _buildSliderSection(
      colors: colors,
      title: l10n.minDiscount,
      valueText: currentVal == 0 ? l10n.all : "+$currentVal%",
      slider: Slider(
        value: currentVal.toDouble(),
        min: 0.0,
        max: 90.0,
        divisions: 18,
        onChanged: (val) => setState(
          () => _localState = _localState.copyWith(
            minDiscount: val.toInt(),
            clearMinDiscount: val == 0,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeSlider(AppColors colors, AppLocalizations l10n) {
    final double currentMin = _localState.minPrice ?? 0.0;
    final double currentMax = _localState.maxPrice ?? _maxAllowedPrice;
    final bool isAnyPrice = currentMin == 0.0 && currentMax == _maxAllowedPrice;

    return _buildSliderSection(
      colors: colors,
      title: l10n.priceRange,
      valueText: isAnyPrice
          ? l10n.all
          : "${currentMin.round()} - ${currentMax.round()} SAR",
      slider: RangeSlider(
        values: RangeValues(currentMin, currentMax),
        min: 0.0,
        max: _maxAllowedPrice,
        divisions: 60,
        onChanged: (RangeValues values) {
          setState(() {
            _localState = _localState.copyWith(
              minPrice: values.start,
              maxPrice: values.end,
              clearMinPrice: values.start == 0.0,
              clearMaxPrice: values.end == _maxAllowedPrice,
            );
          });
        },
      ),
    );
  }

  Widget _buildSliderSection({
    required AppColors colors,
    required String title,
    required String valueText,
    required Widget slider,
  }) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingMedium,
                  vertical: Dimensions.spacingTiny,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMedium),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: colors.primary,
              inactiveTrackColor: colors.iconGrey.withValues(alpha: 0.15),
              thumbColor: colors.surface,
              overlayColor: colors.primary.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 6,
              ),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 6,
              ),
            ),
            child: slider,
          ),
        ],
      ),
    );
  }

  // --- Utilities ---

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Dimensions.spacingMedium,
        right: Dimensions.spacingSmall,
        left: Dimensions.spacingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontTitleMedium,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
      child: Divider(
        height: 1,
        thickness: 1,
        color: colors.iconGrey.withValues(alpha: 0.1),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, AppColors colors) {
    final bool hasActiveFilters = _localState.activeFilterCount > 0;
    return AppBar(
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: colors.background,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        l10n.filters,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: Dimensions.fontHeading3,
        ),
      ),
      actions: [
        if (hasActiveFilters)
          TextButton(
            onPressed: () =>
                setState(() => _localState = const MarketplaceFilterState()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reset,
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: Dimensions.fontBodyMedium,
                  ),
                ),
                SizedBox(width: Dimensions.spacingTiny),
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingTiny),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _localState.activeFilterCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(width: Dimensions.spacingSmall),
      ],
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, AppColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingLarge,
        Dimensions.spacingMedium,
        Dimensions.spacingLarge,
        Dimensions.spacingLarge,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            elevation: 0,
            minimumSize: Size(double.infinity, Dimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            ),
          ),
          onPressed: () {
            ref
                .read(marketplaceFilterProvider.notifier)
                .updateFilters(_localState);
            context.pop();
          },
          child: Text(
            l10n.applyFilters,
            style: TextStyle(
              fontSize: Dimensions.fontButton,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
