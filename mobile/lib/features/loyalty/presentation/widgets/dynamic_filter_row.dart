import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class DynamicFilterRow extends StatelessWidget {
  final Map<String, String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final AppColors colors;

  const DynamicFilterRow({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
      child: Row(
        children: filters.entries.map((entry) {
          final bool isSelected = selectedFilter == entry.key;
          return Padding(
            padding: EdgeInsets.only(
              right: Directionality.of(context) == TextDirection.rtl
                  ? 0
                  : Dimensions.spacingSmall,
              left: Directionality.of(context) == TextDirection.rtl
                  ? Dimensions.spacingSmall
                  : 0,
            ),
            child: ChoiceChip(
              label: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: Dimensions.fontBodyMedium,
                  color: isSelected ? colors.surface : colors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.iconGrey.withValues(alpha: 0.05),
              onSelected: (_) => onFilterChanged(entry.key),
              showCheckmark: false,
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingMedium,
                vertical: Dimensions.spacingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                side: BorderSide(
                  color: isSelected ? colors.primary : Colors.transparent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
