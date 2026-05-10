import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_data_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/explore_filter_state.dart';
import '../providers/explore_provider.dart';

class ExploreFiltersScreen extends ConsumerStatefulWidget {
  const ExploreFiltersScreen({super.key});

  @override
  ConsumerState<ExploreFiltersScreen> createState() =>
      _ExploreFiltersScreenState();
}

class _ExploreFiltersScreenState extends ConsumerState<ExploreFiltersScreen> {
  late ExploreFilterState _localState;

  static const double _maxAllowedPrice = 3000.0;
  static const double _imageCardHeight = 110.0;
  static const double _imageCardWidth = 90.0;

  @override
  void initState() {
    super.initState();
    _localState = ref.read(exploreFilterProvider);
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
              _buildServiceCategoryTabs(colors, staticData.serviceTypes),
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
                      _buildCoreFiltersCard(colors, l10n, staticData.cities),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      ..._buildDynamicFilters(colors, l10n, staticData),

                      _buildSectionTitle(l10n.status, colors),
                      _buildStatusAndSortCard(colors, l10n),

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

  // --- Architecture: Dynamic Render Pipeline ---

  List<Widget> _buildDynamicFilters(
    AppColors colors,
    AppLocalizations l10n,
    dynamic staticData,
  ) {
    switch (_localState.category) {
      case 'gym':
        return _buildGymSpecificFilters(
          colors,
          l10n,
          staticData.sports,
          staticData.amenities,
        );
      case 'trainer':
        return _buildTrainerSpecificFilters(colors, l10n, staticData.sports);
      default:
        return [];
    }
  }

  // --- Specific Service Filters ---

  List<Widget> _buildGymSpecificFilters(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> sports,
    List<Map<String, dynamic>> amenities,
  ) {
    return [
      _buildSectionTitle(l10n.gender, colors),
      _buildSegmentedOptionsCard(
        colors: colors,
        options: {'male': l10n.men, 'female': l10n.women},
        currentValue: _localState.gender,
        onChanged: (val) => setState(() {
          _localState = _localState.gender == val
              ? _localState.copyWith(clearGender: true)
              : _localState.copyWith(gender: val);
        }),
      ),
      SizedBox(height: Dimensions.spacingExtraLarge),

      _buildSectionTitle(l10n.crowdLevel, colors),
      _buildSegmentedOptionsCard(
        colors: colors,
        options: {
          'low': l10n.lowCrowd,
          'medium': l10n.mediumCrowd,
          'high': l10n.highCrowd,
        },
        currentValue: _localState.crowdLevel,
        onChanged: (val) => setState(() {
          _localState = _localState.crowdLevel == val
              ? _localState.copyWith(clearCrowdLevel: true)
              : _localState.copyWith(crowdLevel: val);
        }),
      ),
      SizedBox(height: Dimensions.spacingExtraLarge),

      if (sports.isNotEmpty) ...[
        _buildSectionTitle(l10n.sports, colors),
        _buildHorizontalImageSelector(
          items: sports,
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
          colors: colors,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],

      if (amenities.isNotEmpty) ...[
        _buildSectionTitle(l10n.amenities, colors),
        _buildHorizontalImageSelector(
          items: amenities,
          selectedIds: _localState.selectedAmenities,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedAmenities: val),
          ),
          colors: colors,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
    ];
  }

  List<Widget> _buildTrainerSpecificFilters(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> sports,
  ) {
    return [
      _buildSectionTitle(l10n.gender, colors),
      _buildSegmentedOptionsCard(
        colors: colors,
        options: {'male': l10n.men, 'female': l10n.women},
        currentValue: _localState.gender,
        onChanged: (val) => setState(() {
          _localState = _localState.gender == val
              ? _localState.copyWith(clearGender: true)
              : _localState.copyWith(gender: val);
        }),
      ),
      SizedBox(height: Dimensions.spacingExtraLarge),

      if (sports.isNotEmpty) ...[
        _buildSectionTitle(l10n.specialties, colors),
        _buildHorizontalImageSelector(
          items: sports,
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
          colors: colors,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
    ];
  }

  // --- Premium Core Hub Card ---

  Widget _buildCoreFiltersCard(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> cities,
  ) {
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
      child: Column(
        children: [
          _buildCitySelector(colors, l10n, cities),
          _buildDivider(colors),
          _buildRadiusSlider(colors, l10n),
          _buildDivider(colors),
          _buildPriceRangeSlider(colors, l10n),
        ],
      ),
    );
  }

  Widget _buildStatusAndSortCard(AppColors colors, AppLocalizations l10n) {
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
      child: Column(
        children: [
          _buildOpenNowToggle(colors, l10n),
          _buildDivider(colors),
          _buildSortSelector(colors, l10n),
        ],
      ),
    );
  }

  // --- Rich Media Horizontal Selector (Fixed Premium Design) ---

  Widget _buildHorizontalImageSelector({
    required List<dynamic> items,
    required List<int> selectedIds,
    required Function(List<int>) onChanged,
    required AppColors colors,
  }) {
    return Transform.translate(
      offset: Offset(-Dimensions.spacingLarge, 0),
      child: SizedBox(
        height: _imageCardHeight,
        width: MediaQuery.of(context).size.width,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final int id = item['id'] as int;
            final String name = item['name'].toString();
            final String? imageUrl =
                item['image']?.toString() ?? item['icon']?.toString();

            final bool isSelected = selectedIds.contains(id);
            final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

            return GestureDetector(
              onTap: () {
                final list = List<int>.from(selectedIds);
                isSelected ? list.remove(id) : list.add(id);
                onChanged(list);
              },
              child: Container(
                width: _imageCardWidth,
                margin: EdgeInsets.only(right: Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : colors.iconGrey.withValues(alpha: 0.15),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius - 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: hasImage
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderIcon(colors),
                                  )
                                : _buildPlaceholderIcon(colors),
                          ),
                          Container(
                            color: colors.surface,
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.spacingTiny,
                              vertical: Dimensions.spacingSmall,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.primary
                                    : colors.textPrimary,
                                fontSize: Dimensions.fontBodySmall,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: Dimensions.spacingTiny,
                        right: Dimensions.spacingTiny,
                        child: Container(
                          padding: EdgeInsets.all(Dimensions.spacingTiny / 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: Dimensions.iconSmall,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(AppColors colors) {
    return Container(
      color: colors.background,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: colors.primary.withValues(alpha: 0.3),
          size: Dimensions.iconLarge,
        ),
      ),
    );
  }

  // --- Sub-Components (Inputs & Controls) ---

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
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: Dimensions.fontBodyLarge,
            fontWeight: FontWeight.bold,
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
    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.distance,
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
                  isUnlimited
                      ? l10n.anyDistance
                      : "${_localState.radiusKm.round()} ${l10n.km}",
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
            ),
            child: Slider(
              value: _localState.radiusKm,
              min: 1.0,
              max: 200.0,
              onChanged: (val) => setState(
                () => _localState = _localState.copyWith(radiusKm: val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSlider(AppColors colors, AppLocalizations l10n) {
    final double currentMin = _localState.minPrice ?? 0.0;
    final double currentMax = _localState.maxPrice ?? _maxAllowedPrice;
    final bool isAnyPrice = currentMin == 0.0 && currentMax == _maxAllowedPrice;

    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.priceRange,
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
                  color: isAnyPrice
                      ? colors.iconGrey.withValues(alpha: 0.1)
                      : colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
                child: Text(
                  isAnyPrice
                      ? l10n.anyPrice
                      : "${currentMin.round()} - ${currentMax.round()} ${l10n.sar}",
                  style: TextStyle(
                    color: isAnyPrice ? colors.textSecondary : colors.primary,
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
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 6,
              ),
            ),
            child: RangeSlider(
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
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedOptionsCard({
    required AppColors colors,
    required Map<String, String> options,
    required String? currentValue,
    required Function(String) onChanged,
  }) {
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
                // ARCHITECTURE FIX: Replaced AnimatedContainer with Container to fix Black Flash glitch completely
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
                      color: isSelected ? colors.primary : colors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: Dimensions.fontBodyMedium,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOpenNowToggle(AppColors colors, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.openNow,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Dimensions.fontBodyLarge,
              color: colors.textPrimary,
            ),
          ),
          Switch(
            value: _localState.isOpen,
            activeColor: Colors.white,
            activeTrackColor: colors.primary,
            inactiveThumbColor: colors.iconGrey,
            inactiveTrackColor: colors.iconGrey.withValues(alpha: 0.15),
            onChanged: (val) =>
                setState(() => _localState = _localState.copyWith(isOpen: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSelector(AppColors colors, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sortBy,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Dimensions.fontBodyLarge,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.iconGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            ),
            child: Row(
              children:
                  [
                    {'distance': l10n.distance},
                    {'-rating': l10n.highestRating},
                  ].expand((map) {
                    return map.entries.map((entry) {
                      final isSelected =
                          (_localState.sortBy ?? 'distance') == entry.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _localState = _localState.copyWith(
                              sortBy: entry.key,
                            );
                          }),
                          // ARCHITECTURE FIX: Replaced AnimatedContainer with Container to fix Black Flash glitch completely
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.spacingMedium,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                Dimensions.borderRadius,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colors.shadow.withValues(
                                          alpha: 0.05,
                                        ),
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
                            ),
                          ),
                        ),
                      );
                    });
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Utility Widgets ---

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
            onPressed: () => setState(
              () => _localState = ExploreFilterState(
                category: _localState.category,
              ),
            ),
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

  Widget _buildServiceCategoryTabs(
    AppColors colors,
    List<Map<String, dynamic>> serviceTypes,
  ) {
    if (serviceTypes.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
      child: Row(
        children: serviceTypes.map((type) {
          final id = type['id'].toString();
          final name = type['name'].toString();
          final isSelected = _localState.category == id;
          return GestureDetector(
            onTap: () =>
                setState(() => _localState = ExploreFilterState(category: id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: Dimensions.spacingMedium),
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingExtraLarge,
                vertical: Dimensions.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: Dimensions.fontBodyLarge,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            ref.read(exploreFilterProvider.notifier).updateFilters(_localState);
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
