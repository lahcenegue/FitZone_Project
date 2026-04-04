import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

class ExploreFiltersBottomSheet extends ConsumerStatefulWidget {
  final AppColors colors;

  const ExploreFiltersBottomSheet({super.key, required this.colors});

  @override
  ConsumerState<ExploreFiltersBottomSheet> createState() =>
      _ExploreFiltersBottomSheetState();
}

class _ExploreFiltersBottomSheetState
    extends ConsumerState<ExploreFiltersBottomSheet> {
  static final Logger _logger = Logger('ExploreFilters');
  late ExploreFilterState _localState;

  // SQLite Data
  List<Map<String, dynamic>> _serviceTypes = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _sports = [];
  List<Map<String, dynamic>> _amenities = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _localState = ref.read(exploreFilterProvider);
    _loadStaticData();
  }

  Future<void> _loadStaticData() async {
    final dbService = ref.read(databaseServiceProvider);

    final types = await dbService.getServiceTypes();
    final cities = await dbService.getCities();
    final sports = await dbService.getSports();
    final amenities = await dbService.getAmenities();

    _logger.info(
      'Loaded from DB -> Types: ${types.length}, Cities: ${cities.length}, Sports: ${sports.length}, Amenities: ${amenities.length}',
    );

    if (mounted) {
      setState(() {
        _serviceTypes = types;
        _cities = cities;
        _sports = sports;
        _amenities = amenities;

        // Fallback safety for category if not found in DB
        if (_serviceTypes.isNotEmpty &&
            !_serviceTypes.any((t) => t['id'] == _localState.category)) {
          _localState = _localState.copyWith(
            category: _serviceTypes.first['id'].toString(),
          );
        }

        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      height: Dimensions.heightPercent(92.0),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge * 1.5),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(l10n),
          if (!_isLoadingData) _buildServiceCategorySelector(),
          SizedBox(height: Dimensions.spacingMedium),

          Expanded(
            child: _isLoadingData
                ? Center(
                    child: CircularProgressIndicator(
                      color: widget.colors.primary,
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingLarge,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildDynamicFiltersForm(l10n),
                    ),
                  ),
          ),
          _buildApplyButton(l10n),
        ],
      ),
    );
  }

  /// The core builder that switches sections based on the selected category
  Widget _buildDynamicFiltersForm(AppLocalizations l10n) {
    return Column(
      key: ValueKey<String>(_localState.category),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Location & Distance
        _buildSectionTitle(l10n.cityOrRegion),
        _buildCitySelector(l10n),
        SizedBox(height: Dimensions.spacingLarge),

        _buildSectionTitle(l10n.searchRadiusKm),
        _buildRadiusSlider(l10n),
        SizedBox(height: Dimensions.spacingLarge),

        // 2. Category Specific Filters
        if (_localState.category == 'gym') ..._buildGymFilters(l10n),
        if (_localState.category == 'trainer') ..._buildTrainerFilters(l10n),
        // Future extensions for Food & Equipment can go here...

        // 3. Price Filter (Shared)
        _buildSectionTitle("الحد الأقصى للسعر"), // TODO: Use l10n.maxPrice
        _buildPriceSlider(l10n),
        SizedBox(height: Dimensions.spacingLarge),

        // 4. Status (Shared)
        _buildOpenNowToggle(l10n),
        SizedBox(height: Dimensions.spacingLarge),

        // 5. Sorting (Shared)
        _buildSectionTitle(l10n.sortBy),
        _buildSortSelector(l10n),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
    );
  }

  // ---------------------------------------------------------
  // SECTION: SPECIFIC FILTERS
  // ---------------------------------------------------------

  List<Widget> _buildGymFilters(AppLocalizations l10n) {
    return [
      _buildSectionTitle(l10n.gender),
      _buildGenderSelector(l10n),
      SizedBox(height: Dimensions.spacingLarge),

      if (_sports.isNotEmpty) ...[
        _buildSectionTitle(l10n.sports),
        _buildDynamicMultiSelectChips(
          items: _sports,
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
        ),
        SizedBox(height: Dimensions.spacingLarge),
      ],

      if (_amenities.isNotEmpty) ...[
        _buildSectionTitle(l10n.amenities),
        _buildDynamicMultiSelectChips(
          items: _amenities,
          selectedIds: _localState.selectedAmenities,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedAmenities: val),
          ),
        ),
        SizedBox(height: Dimensions.spacingLarge),
      ],
    ];
  }

  List<Widget> _buildTrainerFilters(AppLocalizations l10n) {
    return [
      _buildSectionTitle(l10n.gender),
      _buildGenderSelector(l10n),
      SizedBox(height: Dimensions.spacingLarge),

      if (_sports.isNotEmpty) ...[
        _buildSectionTitle(
          l10n.specialties,
        ), // Uses sports data for trainer specialties
        _buildDynamicMultiSelectChips(
          items: _sports,
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
        ),
        SizedBox(height: Dimensions.spacingLarge),
      ],
    ];
  }

  // ---------------------------------------------------------
  // SECTION: PREMIUM UI COMPONENTS
  // ---------------------------------------------------------

  Widget _buildServiceCategorySelector() {
    if (_serviceTypes.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _serviceTypes.map((type) {
          final String id = type['id'].toString();
          final String name = type['name'].toString();

          IconData icon = Icons.fitness_center;
          if (id == 'trainer') icon = Icons.sports_martial_arts;
          if (id == 'restaurant') icon = Icons.restaurant_menu;
          if (id == 'equipment') icon = Icons.storefront;

          return Padding(
            padding: EdgeInsets.only(right: Dimensions.spacingMedium),
            child: _buildCategoryCard(name, icon, id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(String label, IconData icon, String categoryId) {
    final bool isSelected = _localState.category == categoryId;
    return GestureDetector(
      onTap: () {
        setState(() => _localState = ExploreFilterState(category: categoryId));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.spacingLarge,
          vertical: Dimensions.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: isSelected ? widget.colors.primary : widget.colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: isSelected
                ? widget.colors.primary
                : widget.colors.iconGrey.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.colors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: Dimensions.iconMedium,
              color: isSelected ? Colors.white : widget.colors.iconGrey,
            ),
            SizedBox(width: Dimensions.spacingSmall),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : widget.colors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: Dimensions.fontBodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector(AppLocalizations l10n) {
    if (_cities.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      value: _localState.cityId,
      isExpanded: true,
      dropdownColor: widget.colors.surface,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: widget.colors.primary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimensions.spacingLarge,
          vertical: Dimensions.spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(
            color: widget.colors.iconGrey.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(
            color: widget.colors.iconGrey.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(color: widget.colors.primary, width: 2),
        ),
      ),
      hint: Text(
        l10n.selectRegion,
        style: TextStyle(color: widget.colors.iconGrey),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.allRegions,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ..._cities.map((city) {
          return DropdownMenuItem<String>(
            value: city['id'].toString(),
            child: Text(
              city['name'].toString(),
              style: TextStyle(color: widget.colors.textPrimary),
            ),
          );
        }),
      ],
      onChanged: (val) =>
          setState(() => _localState = _localState.copyWith(cityId: val)),
    );
  }

  Widget _buildRadiusSlider(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingLarge,
        Dimensions.spacingLarge,
        Dimensions.spacingLarge,
        Dimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: widget.colors.iconGrey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    color: widget.colors.primary,
                    size: Dimensions.iconMedium,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    "المسافة", // TODO: Use l10n
                    style: TextStyle(
                      color: widget.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                "${_localState.radiusKm.round()} ${l10n.km}",
                style: TextStyle(
                  color: widget.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontTitleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingSmall),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: widget.colors.primary,
              inactiveTrackColor: widget.colors.primary.withOpacity(0.1),
              thumbColor: widget.colors.primary,
              overlayColor: widget.colors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _localState.radiusKm,
              min: 1.0,
              max: 200.0,
              divisions: 199,
              onChanged: (val) => setState(
                () => _localState = _localState.copyWith(radiusKm: val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSlider(AppLocalizations l10n) {
    final double currentPrice = _localState.maxPrice ?? 1500.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingLarge,
        Dimensions.spacingLarge,
        Dimensions.spacingLarge,
        Dimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: widget.colors.iconGrey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    color: widget.colors.primary,
                    size: Dimensions.iconMedium,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    "السعر", // TODO: Use l10n
                    style: TextStyle(
                      color: widget.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                _localState.maxPrice == null
                    ? "أي سعر"
                    : "${currentPrice.round()} ${l10n.sar}",
                style: TextStyle(
                  color: widget.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontTitleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingSmall),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: widget.colors.primary,
              inactiveTrackColor: widget.colors.primary.withOpacity(0.1),
              thumbColor: widget.colors.primary,
            ),
            child: Slider(
              value: currentPrice,
              min: 50.0,
              max: 1500.0,
              divisions: 29,
              onChanged: (val) {
                setState(() {
                  _localState = _localState.copyWith(
                    maxPrice: val >= 1500.0 ? null : val,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicMultiSelectChips({
    required List<dynamic> items,
    required List<int> selectedIds,
    required Function(List<int>) onChanged,
  }) {
    return Wrap(
      spacing: Dimensions.spacingMedium,
      runSpacing: Dimensions.spacingMedium,
      children: items.map((item) {
        final int id = item['id'] as int;
        final String name = item['name'] as String;
        final bool isSelected = selectedIds.contains(id);

        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (val) {
            final List<int> currentList = List<int>.from(selectedIds);
            if (val) {
              currentList.add(id);
            } else {
              currentList.remove(id);
            }
            onChanged(currentList);
          },
          showCheckmark: false,
          backgroundColor: widget.colors.surface,
          selectedColor: widget.colors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : widget.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: Dimensions.fontBodyMedium,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.spacingMedium,
            vertical: Dimensions.spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            side: BorderSide(
              color: isSelected
                  ? widget.colors.primary
                  : widget.colors.iconGrey.withOpacity(0.2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector(AppLocalizations l10n) {
    return Row(
      children: [
        _buildSelectableButton(
          l10n.male,
          _localState.gender == 'male',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'male'),
          ),
        ),
        SizedBox(width: Dimensions.spacingMedium),
        _buildSelectableButton(
          l10n.female,
          _localState.gender == 'female',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'female'),
          ),
        ),
        SizedBox(width: Dimensions.spacingMedium),
        _buildSelectableButton(
          l10n.mixed,
          _localState.gender == 'mixed',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'mixed'),
          ),
        ),
      ],
    );
  }

  Widget _buildSortSelector(AppLocalizations l10n) {
    return Row(
      children: [
        _buildSelectableButton(
          l10n.distance,
          _localState.sortBy == 'distance',
          () => setState(
            () => _localState = _localState.copyWith(sortBy: 'distance'),
          ),
        ),
        SizedBox(width: Dimensions.spacingMedium),
        _buildSelectableButton(
          l10n.highestRating,
          _localState.sortBy == '-rating',
          () => setState(
            () => _localState = _localState.copyWith(sortBy: '-rating'),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: Dimensions.spacingMedium),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? widget.colors.primary.withOpacity(0.1)
                : widget.colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: isSelected
                  ? widget.colors.primary
                  : widget.colors.iconGrey.withOpacity(0.2),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? widget.colors.primary
                  : widget.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenNowToggle(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: widget.colors.iconGrey.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: widget.colors.primary,
                size: Dimensions.iconLarge,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              Text(
                l10n.openNow,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontTitleMedium,
                  color: widget.colors.textPrimary,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: _localState.isOpen,
            activeColor: widget.colors.primary,
            onChanged: (val) =>
                setState(() => _localState = _localState.copyWith(isOpen: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingExtraLarge,
        Dimensions.spacingMedium,
        Dimensions.spacingExtraLarge,
        Dimensions.spacingLarge,
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: widget.colors.iconGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: Dimensions.spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filters,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading2,
                  fontWeight: FontWeight.w900,
                  color: widget.colors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => setState(
                  () => _localState = ExploreFilterState(
                    category: _localState.category,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: widget.colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.reset,
                    style: TextStyle(
                      color: widget.colors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: Dimensions.fontBodyMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Dimensions.spacingMedium,
        top: Dimensions.spacingMedium,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontTitleMedium,
          fontWeight: FontWeight.w800,
          color: widget.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildApplyButton(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingExtraLarge,
        Dimensions.spacingMedium,
        Dimensions.spacingExtraLarge,
        Dimensions.spacingExtraLarge,
      ),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.colors.primary,
          minimumSize: Size(double.infinity, Dimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
          elevation: 0,
        ),
        onPressed: () {
          ref.read(exploreFilterProvider.notifier).updateFilters(_localState);
          Navigator.pop(context);
        },
        child: Text(
          l10n.applyFilters,
          style: TextStyle(
            fontSize: Dimensions.fontButton,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
