import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';

class ExploreSearchBar extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const ExploreSearchBar({
    super.key,
    required this.colors,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      height: Dimensions.searchBarHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            spreadRadius: Dimensions.shadowSpreadRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusPill),
          onTap: onSearchTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingMedium),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: colors.iconGrey,
                  size: Dimensions.iconMedium,
                ),
                SizedBox(width: Dimensions.spacingSmall),
                Expanded(
                  child: Text(
                    l10n.search,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: Dimensions.fontBodyLarge,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  height: Dimensions.spacingLarge,
                  width: Dimensions.dividerHeight,
                  color: colors.background,
                  margin: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingSmall,
                  ),
                ),
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    padding: EdgeInsets.all(Dimensions.spacingTiny),
                    child: Icon(
                      Icons.tune,
                      color: colors.textPrimary,
                      size: Dimensions.iconMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
