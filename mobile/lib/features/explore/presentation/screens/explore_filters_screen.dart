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

  bool _showAllSports = false;
  bool _showAllAmenities = false;

  @override
  void initState() {
    super.initState();
    // Initialize the local state form with the current active filters
    _localState = ref.read(exploreFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final staticDataAsync = ref.watch(filterStaticDataProvider);

    return Scaffold(
      backgroundColor: colors.background,
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
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(l10n, colors, staticData.serviceTypes),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Dimensions.spacingLarge),
                      _buildSectionTitle(l10n.cityOrRegion, colors),
                      _buildCitySelector(colors, l10n, staticData.cities),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.searchRadiusKm, colors),
                      _buildRadiusSlider(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      // Dynamic Category Injection
                      if (_localState.category == 'gym')
                        ..._buildGymFilters(
                          l10n,
                          colors,
                          staticData.sports,
                          staticData.amenities,
                        ),
                      if (_localState.category == 'trainer')
                        ..._buildTrainerFilters(
                          l10n,
                          colors,
                          staticData.sports,
                        ),

                      _buildSectionTitle(l10n.maxPriceLimit, colors),
                      _buildPriceInputs(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.status, colors),
                      _buildOpenNowToggle(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      _buildSectionTitle(l10n.sortBy, colors),
                      _buildSortSelector(colors, l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge * 3),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(l10n, colors),
    );
  }

  SliverAppBar _buildSliverAppBar(
    AppLocalizations l10n,
    AppColors colors,
    List<Map<String, dynamic>> serviceTypes,
  ) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: colors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        l10n.filters,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: Dimensions.fontHeading2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(
            () => _localState = ExploreFilterState(
              category: _localState.category,
            ),
          ),
          child: Text(
            l10n.reset,
            style: TextStyle(color: colors.error, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
          child: _buildServiceCategoryTabs(colors, serviceTypes),
        ),
      ),
    );
  }

  // --- Dynamic Form Parts ---

  List<Widget> _buildGymFilters(
    AppLocalizations l10n,
    AppColors colors,
    List<Map<String, dynamic>> sports,
    List<Map<String, dynamic>> amenities,
  ) {
    return [
      _buildSectionTitle(l10n.gender, colors),
      _buildGenderSelector(colors, l10n),
      SizedBox(height: Dimensions.spacingExtraLarge),
      if (sports.isNotEmpty) ...[
        _buildSectionTitle(l10n.sports, colors),
        _buildExpandableGrid(
          sports,
          _localState.selectedSports,
          _showAllSports,
          (val) => setState(() => _showAllSports = val),
          (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
          colors,
          l10n,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
      if (amenities.isNotEmpty) ...[
        _buildSectionTitle(l10n.amenities, colors),
        _buildExpandableGrid(
          amenities,
          _localState.selectedAmenities,
          _showAllAmenities,
          (val) => setState(() => _showAllAmenities = val),
          (val) => setState(
            () => _localState = _localState.copyWith(selectedAmenities: val),
          ),
          colors,
          l10n,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
    ];
  }

  List<Widget> _buildTrainerFilters(
    AppLocalizations l10n,
    AppColors colors,
    List<Map<String, dynamic>> sports,
  ) {
    return [
      _buildSectionTitle(l10n.gender, colors),
      _buildGenderSelector(colors, l10n),
      SizedBox(height: Dimensions.spacingExtraLarge),
      if (sports.isNotEmpty) ...[
        _buildSectionTitle(l10n.specialties, colors),
        _buildExpandableGrid(
          sports,
          _localState.selectedSports,
          _showAllSports,
          (val) => setState(() => _showAllSports = val),
          (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
          colors,
          l10n,
        ),
        SizedBox(height: Dimensions.spacingExtraLarge),
      ],
    ];
  }

  // --- Premium UI Widgets ---

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
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: Dimensions.spacingMedium),
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingLarge,
                vertical: Dimensions.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.background,
                borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? colors.primary
                      : colors.iconGrey.withOpacity(0.2),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCitySelector(
    AppColors colors,
    AppLocalizations l10n,
    List<Map<String, dynamic>> cities,
  ) {
    return DropdownButtonFormField<String>(
      value: _localState.cityId,
      dropdownColor: colors.surface,
      icon: Icon(Icons.location_city_rounded, color: colors.primary),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.all(Dimensions.spacingLarge),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(l10n.selectRegion, style: TextStyle(color: colors.iconGrey)),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(
            l10n.allRegions,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        ...cities.map(
          (city) => DropdownMenuItem<String>(
            value: city['id'].toString(),
            child: Text(
              city['name'].toString(),
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
        ),
      ],
      onChanged: (val) =>
          setState(() => _localState = _localState.copyWith(cityId: val)),
    );
  }

  Widget _buildRadiusSlider(AppColors colors, AppLocalizations l10n) {
    final bool isUnlimited = _localState.radiusKm >= 200.0;
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.distance,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isUnlimited
                    ? l10n.anyDistance
                    : "${_localState.radiusKm.round()} ${l10n.km}",
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontTitleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Slider(
            value: _localState.radiusKm,
            min: 1.0,
            max: 200.0,
            activeColor: colors.primary,
            inactiveColor: colors.primary.withOpacity(0.1),
            onChanged: (val) => setState(
              () => _localState = _localState.copyWith(radiusKm: val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputs(AppColors colors, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildPriceTextField(
            label: l10n.minPrice,
            initialValue: _localState.minPrice,
            colors: colors,
            onChanged: (val) {
              final double? parsed = double.tryParse(val);
              setState(
                () => _localState = _localState.copyWith(
                  minPrice: parsed,
                  clearMinPrice: val.isEmpty,
                ),
              );
            },
          ),
        ),
        SizedBox(width: Dimensions.spacingLarge),
        Expanded(
          child: _buildPriceTextField(
            label: l10n.maxPrice,
            initialValue: _localState.maxPrice,
            colors: colors,
            onChanged: (val) {
              final double? parsed = double.tryParse(val);
              setState(
                () => _localState = _localState.copyWith(
                  maxPrice: parsed,
                  clearMaxPrice: val.isEmpty,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTextField({
    required String label,
    required double? initialValue,
    required AppColors colors,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue?.toStringAsFixed(0) ?? '',
      keyboardType: TextInputType.number,
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimensions.spacingLarge,
          vertical: Dimensions.spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildExpandableGrid(
    List<dynamic> items,
    List<int> selectedIds,
    bool isExpanded,
    Function(bool) onExpandToggle,
    Function(List<int>) onChanged,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    final int displayCount = isExpanded
        ? items.length
        : (items.length > 6 ? 6 : items.length);
    final int hiddenCount = items.length - 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Dimensions.spacingMedium,
          runSpacing: Dimensions.spacingMedium,
          children: items.take(displayCount).map((item) {
            final int id = item['id'] as int;
            final bool isSelected = selectedIds.contains(id);
            return GestureDetector(
              onTap: () {
                final list = List<int>.from(selectedIds);
                isSelected ? list.remove(id) : list.add(id);
                onChanged(list);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingMedium,
                  vertical: Dimensions.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : colors.iconGrey.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  item['name'].toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (items.length > 6)
          Padding(
            padding: EdgeInsets.only(top: Dimensions.spacingMedium),
            child: InkWell(
              onTap: () => onExpandToggle(!isExpanded),
              child: Text(
                isExpanded
                    ? l10n.showLess
                    : l10n.showAll(hiddenCount.toString()),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderSelector(AppColors colors, AppLocalizations l10n) {
    return Row(
      children: [
        _buildSelectableButton(
          l10n.men,
          _localState.gender == 'male',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'male'),
          ),
          colors,
        ),
        SizedBox(width: Dimensions.spacingMedium),
        _buildSelectableButton(
          l10n.women,
          _localState.gender == 'female',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'female'),
          ),
          colors,
        ),
      ],
    );
  }

  Widget _buildSortSelector(AppColors colors, AppLocalizations l10n) {
    return _buildSegmentedControl(
      colors,
      {'distance': l10n.distance, '-rating': l10n.highestRating},
      _localState.sortBy,
      (val) => setState(() => _localState = _localState.copyWith(sortBy: val)),
    );
  }

  Widget _buildSegmentedControl(
    AppColors colors,
    Map<String, String> options,
    String? currentValue,
    Function(String) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingTiny),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = currentValue == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.spacingMedium,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpenNowToggle(AppColors colors, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.openNow,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Dimensions.fontTitleMedium,
              color: colors.textPrimary,
            ),
          ),
          Switch.adaptive(
            value: _localState.isOpen,
            activeColor: colors.primary,
            onChanged: (val) =>
                setState(() => _localState = _localState.copyWith(isOpen: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontTitleMedium,
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, AppColors colors) {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            minimumSize: Size(double.infinity, Dimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
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
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    AppColors colors,
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
                ? colors.primary.withOpacity(0.1)
                : colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.iconGrey.withOpacity(0.2),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.primary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
