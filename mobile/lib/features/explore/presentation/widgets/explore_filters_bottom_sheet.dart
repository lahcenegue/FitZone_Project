import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/storage_provider.dart';

class ExploreFiltersBottomSheet extends ConsumerStatefulWidget {
  final AppColors colors;

  const ExploreFiltersBottomSheet({super.key, required this.colors});

  @override
  ConsumerState<ExploreFiltersBottomSheet> createState() =>
      _ExploreFiltersBottomSheetState();
}

class _ExploreFiltersBottomSheetState
    extends ConsumerState<ExploreFiltersBottomSheet> {
  late ExploreFilterState _localState;

  @override
  void initState() {
    super.initState();
    _localState = ref.read(exploreFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(l10n),
          _buildServiceCategorySelector(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildDynamicFiltersForm(l10n),
              ),
            ),
          ),
          _buildApplyButton(l10n),
        ],
      ),
    );
  }

  /// The master form builder that switches context based on Category
  Widget _buildDynamicFiltersForm(AppLocalizations l10n) {
    // Unique key forces AnimatedSwitcher to trigger animation on category change
    return Column(
      key: ValueKey<ServiceCategory>(_localState.category),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("City / Region"),
        _buildCitySelector(),
        const SizedBox(height: 24),

        _buildSectionTitle("Search Radius (km)"),
        _buildRadiusSlider(),
        const SizedBox(height: 24),

        // Dynamic Injection based on Type
        if (_localState.category == ServiceCategory.gym)
          ..._buildGymFilters(l10n),
        if (_localState.category == ServiceCategory.trainer)
          ..._buildTrainerFilters(l10n),
        if (_localState.category == ServiceCategory.restaurant)
          ..._buildRestaurantFilters(l10n),
        if (_localState.category == ServiceCategory.equipment)
          ..._buildEquipmentFilters(l10n),

        _buildOpenNowToggle(l10n),
        const SizedBox(height: 24),

        _buildSectionTitle(l10n.sortBy),
        _buildSortSelector(l10n),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- Specific Filter Sets ---

  List<Widget> _buildGymFilters(AppLocalizations l10n) {
    final storage = ref.read(storageServiceProvider);
    return [
      _buildSectionTitle(l10n.gender),
      _buildGenderSelector(),
      const SizedBox(height: 24),
      if (storage.sportsData.isNotEmpty) ...[
        _buildSectionTitle("Sports"),
        _buildDynamicMultiSelectChips(
          items: storage.sportsData,
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
        ),
        const SizedBox(height: 24),
      ],
      if (storage.amenitiesData.isNotEmpty) ...[
        _buildSectionTitle("Amenities"),
        _buildDynamicMultiSelectChips(
          items: storage.amenitiesData,
          selectedIds: _localState.selectedAmenities,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedAmenities: val),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ];
  }

  List<Widget> _buildTrainerFilters(AppLocalizations l10n) {
    final storage = ref.read(storageServiceProvider);
    return [
      _buildSectionTitle(l10n.gender),
      _buildGenderSelector(),
      const SizedBox(height: 24),
      if (storage.sportsData.isNotEmpty) ...[
        _buildSectionTitle("Specialties"),
        _buildDynamicMultiSelectChips(
          items: storage.sportsData, // Trainers reuse sports as specialties
          selectedIds: _localState.selectedSports,
          onChanged: (val) => setState(
            () => _localState = _localState.copyWith(selectedSports: val),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ];
  }

  List<Widget> _buildRestaurantFilters(AppLocalizations l10n) {
    // Note: Dummy data until SQLite migration and Backend update is ready
    final List<Map<String, dynamic>> dummyDietary = [
      {'id': 1, 'name': 'Keto'},
      {'id': 2, 'name': 'Vegan'},
      {'id': 3, 'name': 'High Protein'},
    ];
    return [
      _buildSectionTitle("Dietary Options"),
      _buildDynamicMultiSelectChips(
        items: dummyDietary,
        selectedIds: _localState.selectedDietary,
        onChanged: (val) => setState(
          () => _localState = _localState.copyWith(selectedDietary: val),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildEquipmentFilters(AppLocalizations l10n) {
    final List<Map<String, dynamic>> dummyEq = [
      {'id': 1, 'name': 'Supplements'},
      {'id': 2, 'name': 'Machines'},
      {'id': 3, 'name': 'Apparel'},
    ];
    return [
      _buildSectionTitle("Categories"),
      _buildDynamicMultiSelectChips(
        items: dummyEq,
        selectedIds: _localState.selectedEquipmentCategories,
        onChanged: (val) => setState(
          () => _localState = _localState.copyWith(
            selectedEquipmentCategories: val,
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  // --- Premium UI Components ---

  Widget _buildServiceCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildCategoryCard("Gyms", Icons.fitness_center, ServiceCategory.gym),
          const SizedBox(width: 12),
          _buildCategoryCard(
            "Trainers",
            Icons.sports_martial_arts,
            ServiceCategory.trainer,
          ),
          const SizedBox(width: 12),
          _buildCategoryCard(
            "Food",
            Icons.restaurant_menu,
            ServiceCategory.restaurant,
          ),
          const SizedBox(width: 12),
          _buildCategoryCard(
            "Stores",
            Icons.storefront,
            ServiceCategory.equipment,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String label,
    IconData icon,
    ServiceCategory category,
  ) {
    final bool isSelected = _localState.category == category;
    return GestureDetector(
      onTap: () {
        // Reset state entirely when switching main categories to avoid conflicting filters
        setState(() => _localState = ExploreFilterState(category: category));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? widget.colors.primary : widget.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? widget.colors.primary
                : widget.colors.iconGrey.withOpacity(0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.colors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : widget.colors.iconGrey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : widget.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    final storage = ref.read(storageServiceProvider);
    final cities = storage.citiesData;

    if (cities.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      value: _localState.cityId,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      hint: const Text("Select Region/City"),
      items: [
        const DropdownMenuItem(value: null, child: Text("All Regions")),
        ...cities.map((city) {
          return DropdownMenuItem<String>(
            value: city['id'].toString(),
            child: Text(city['name'].toString()),
          );
        }),
      ],
      onChanged: (val) =>
          setState(() => _localState = _localState.copyWith(cityId: val)),
    );
  }

  Widget _buildDynamicMultiSelectChips({
    required List<dynamic> items,
    required List<int> selectedIds,
    required Function(List<int>) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
          backgroundColor: widget.colors.surface,
          selectedColor: widget.colors.primary.withOpacity(0.15),
          checkmarkColor: widget.colors.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? widget.colors.primary
                : widget.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? widget.colors.primary.withOpacity(0.5)
                  : widget.colors.iconGrey.withOpacity(0.2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadiusSlider() {
    return Column(
      children: [
        Slider.adaptive(
          value: _localState.radiusKm,
          min: 1.0,
          max: 200.0,
          divisions: 20,
          activeColor: widget.colors.primary,
          label: "${_localState.radiusKm.round()} km",
          onChanged: (val) =>
              setState(() => _localState = _localState.copyWith(radiusKm: val)),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.colors.iconGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filters,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: widget.colors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _localState = const ExploreFilterState()),
                child: Text(
                  l10n.reset,
                  style: TextStyle(
                    color: widget.colors.error,
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: widget.colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _buildSelectableButton(
          "Male",
          _localState.gender == 'male',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'male'),
          ),
        ),
        const SizedBox(width: 8),
        _buildSelectableButton(
          "Female",
          _localState.gender == 'female',
          () => setState(
            () => _localState = _localState.copyWith(gender: 'female'),
          ),
        ),
        const SizedBox(width: 8),
        _buildSelectableButton(
          "Mixed",
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
        const SizedBox(width: 12),
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

  Widget _buildOpenNowToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.colors.iconGrey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.openNow,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSelectableButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? widget.colors.primary : widget.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? widget.colors.primary
                  : widget.colors.iconGrey.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : widget.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.colors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: () {
          ref.read(exploreFilterProvider.notifier).updateFilters(_localState);
          Navigator.pop(context);
        },
        child: Text(
          l10n.applyFilters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
