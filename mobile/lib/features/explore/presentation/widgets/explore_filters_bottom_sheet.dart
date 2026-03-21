import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

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
  // قيم تجريبية للرياضات والخدمات حتى يتم ربطها بالباك اند
  final List<String> _allSports = [
    'football',
    'Boxing',
    'Swimming',
    'Tennis',
    'Gymnastics',
  ];
  final List<String> _allAmenities = [
    'ساونا',
    'مسبح',
    'WiFi',
    'Parking',
    'Steam Room',
  ];

  @override
  void initState() {
    super.initState();
    _localState = ref.read(exploreFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(l10n),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(l10n.category),
                  _buildCategorySelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Search Radius (km)"), // مساحة البحث
                  _buildRadiusSlider(),
                  const SizedBox(height: 24),

                  _buildSectionTitle(l10n.gender),
                  _buildGenderSelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Sports"), // اختيار الرياضة
                  _buildMultiSelectChips(_allSports, "sports"),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Amenities"), // اختيار الخدمات
                  _buildMultiSelectChips(_allAmenities, "amenities"),
                  const SizedBox(height: 24),

                  _buildOpenNowToggle(l10n),
                  const SizedBox(height: 24),

                  _buildSectionTitle(l10n.sortBy),
                  _buildSortSelector(l10n),
                  const SizedBox(height: 100), // مساحة للزر الثابت
                ],
              ),
            ),
          ),
          _buildApplyButton(l10n),
        ],
      ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "1km",
                style: TextStyle(
                  color: widget.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                "100km",
                style: TextStyle(
                  color: widget.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(List<String> items, String type) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        // منطق الاختيار المتعدد (يحتاج إضافة حقول للمصفوفات في ExploreFilterState)
        bool isSelected = false;
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (val) {},
          backgroundColor: widget.colors.surface,
          selectedColor: widget.colors.primary.withOpacity(0.2),
          checkmarkColor: widget.colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: widget.colors.iconGrey.withOpacity(0.2)),
          ),
        );
      }).toList(),
    );
  }

  // ... أكواد selector المختصرة (Category, Gender, Sort) تعتمد على _buildChip الموحد

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

  // دالة بناء الـ Open Now بشكل احترافي
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

  // دوال الاختيار الموحدة (Category, Gender, Sort)
  Widget _buildCategorySelector() {
    return Row(
      children: [
        _buildSelectableButton(
          "Gym",
          _localState.type == 'gym',
          () => setState(() => _localState = _localState.copyWith(type: 'gym')),
        ),
        const SizedBox(width: 12),
        _buildSelectableButton(
          "Trainer",
          _localState.type == 'trainer',
          () => setState(
            () => _localState = _localState.copyWith(type: 'trainer'),
          ),
        ),
      ],
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
}
