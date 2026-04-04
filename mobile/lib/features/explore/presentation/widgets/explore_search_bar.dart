import 'package:fitzone/core/routing/app_router.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class ExploreSearchBar extends ConsumerStatefulWidget {
  final AppColors colors;

  const ExploreSearchBar({super.key, required this.colors});

  @override
  ConsumerState<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends ConsumerState<ExploreSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final String initialQuery = ref.read(exploreFilterProvider).query ?? '';
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final ExploreFilterState currentState = ref.read(exploreFilterProvider);
    ref
        .read(exploreFilterProvider.notifier)
        .updateFilters(currentState.copyWith(query: query));
    FocusScope.of(context).unfocus();
  }

  void _openFilters() {
    context.push(RoutePaths.filters);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ExploreFilterState currentFilters = ref.watch(exploreFilterProvider);

    // Dynamic indicator logic based on comprehensive state
    final bool hasActiveFilters =
        currentFilters.gender != null ||
        currentFilters.isOpen ||
        currentFilters.sortBy != null ||
        currentFilters.selectedSports.isNotEmpty ||
        currentFilters.selectedAmenities.isNotEmpty ||
        currentFilters.maxPrice != null;

    return Container(
      height: Dimensions.searchBarHeight,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withOpacity(0.1),
            blurRadius: Dimensions.shadowBlurRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: Dimensions.spacingMedium),
          Icon(
            Icons.search_rounded,
            color: widget.colors.textSecondary,
            size: Dimensions.iconMedium,
          ),
          SizedBox(width: Dimensions.spacingSmall),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: widget.colors.textPrimary,
                fontSize: Dimensions.fontBodyLarge,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchPlaces,
                hintStyle: TextStyle(
                  color: widget.colors.iconGrey,
                  fontSize: Dimensions.fontBodyLarge,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: widget.colors.iconGrey,
                size: Dimensions.iconSmall,
              ),
              onPressed: () {
                _searchController.clear();
                _onSearchSubmitted('');
              },
            ),
          Container(
            width: 1,
            height: Dimensions.iconMedium,
            color: widget.colors.iconGrey.withOpacity(0.3),
            margin: EdgeInsets.symmetric(horizontal: Dimensions.spacingTiny),
          ),
          Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: currentFilters.activeFilterCount > 0
                      ? widget.colors.primary
                      : widget.colors.textSecondary,
                ),
                onPressed: _openFilters,
              ),
              if (currentFilters.activeFilterCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.colors.surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      currentFilters.activeFilterCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.fontBodySmall * 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: Dimensions.spacingTiny),
        ],
      ),
    );
  }
}
