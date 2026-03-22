import 'package:fitzone/features/explore/presentation/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'explore_filters_bottom_sheet.dart';

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
    final initialQuery = ref.read(exploreFilterProvider).query ?? '';
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final currentState = ref.read(exploreFilterProvider);
    ref.read(exploreFilterProvider.notifier).state = currentState.copyWith(
      query: query,
    );
    FocusScope.of(context).unfocus();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return ExploreFiltersBottomSheet(colors: widget.colors);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentFilters = ref.watch(exploreFilterProvider);

    // Determine if any deep filter is active to show a visual indicator
    final bool hasActiveFilters =
        currentFilters.gender != null ||
        currentFilters.isOpen ||
        currentFilters.sortBy != null;

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
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilters
                      ? widget.colors.primary
                      : widget.colors.textSecondary,
                ),
                onPressed: _openFilters,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.colors.surface,
                        width: 1.5,
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
