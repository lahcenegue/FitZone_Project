import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A globally reusable, highly premium search bar with filter integration.
class PremiumSearchBar extends StatefulWidget {
  final AppColors colors;
  final String hintText;
  final String initialQuery;
  final int activeFilterCount;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onFilterTapped;
  final VoidCallback onClearTapped;

  const PremiumSearchBar({
    super.key,
    required this.colors,
    required this.hintText,
    required this.initialQuery,
    required this.activeFilterCount,
    required this.onSearchSubmitted,
    required this.onFilterTapped,
    required this.onClearTapped,
  });

  @override
  State<PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<PremiumSearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant PremiumSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _searchController.text != widget.initialQuery) {
      _searchController.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearchSubmitted(_searchController.text.trim());
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _searchController.clear();
    widget.onClearTapped();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimensions.searchBarHeight,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.1),
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
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: widget.colors.textPrimary,
                fontSize: Dimensions.fontBodyLarge,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
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
              onPressed: _clear,
            ),
          Container(
            width: 1,
            height: Dimensions.iconMedium,
            color: widget.colors.iconGrey.withValues(alpha: 0.3),
            margin: EdgeInsets.symmetric(horizontal: Dimensions.spacingTiny),
          ),
          Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: widget.activeFilterCount > 0
                      ? widget.colors.primary
                      : widget.colors.textSecondary,
                ),
                onPressed: widget.onFilterTapped,
              ),
              if (widget.activeFilterCount > 0)
                Positioned(
                  top: Dimensions.spacingTiny,
                  right: Dimensions.spacingTiny,
                  child: Container(
                    padding: EdgeInsets.all(Dimensions.spacingTiny),
                    decoration: BoxDecoration(
                      color: widget.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.colors.surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      widget.activeFilterCount.toString(),
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
