import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_theme_provider.dart';
import '../../l10n/app_localizations.dart';

class MainShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: Dimensions.spacingMedium,
            left: Dimensions.spacingLarge,
            right: Dimensions.spacingLarge,
          ),
          child: Container(
            // ARCHITECTURE FIX: Completely removed fixed heights.
            // Let the internal padding and children dictate the size natively.
            padding: EdgeInsets.only(
              top: Dimensions.spacingSmall,
              bottom: Dimensions.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
            ),
            child: Row(
              // Align to bottom to keep all text baselines perfectly matching
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStandardTab(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  l10n.navHome,
                  colors,
                ),
                _buildStandardTab(
                  1,
                  Icons.storefront_outlined,
                  Icons.storefront_rounded,
                  l10n.navMarketplace,
                  colors,
                ),

                // The Contained Hero Tab
                _buildHeroTab(2, l10n.navExplore, colors),

                _buildStandardTab(
                  3,
                  Icons.bookmark_border_rounded,
                  Icons.bookmark_rounded,
                  l10n.navSaved,
                  colors,
                ),
                _buildStandardTab(
                  4,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  l10n.navProfile,
                  colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardTab(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    AppColors colors,
  ) {
    final bool isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? colors.primary : colors.iconGrey,
                size: Dimensions.iconMedium,
              ),
            ),
            SizedBox(height: Dimensions.spacingTiny),
            Text(
              label,
              style: TextStyle(
                fontSize: Dimensions.fontBodySmall * 0.85,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTab(int index, String label, AppColors colors) {
    final bool isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // The Hero Icon Background
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(Dimensions.spacingSmall),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_rounded,
                color: isSelected ? Colors.white : colors.primary,
                size: Dimensions.iconMedium,
              ),
            ),
            SizedBox(height: Dimensions.spacingTiny),
            Text(
              label,
              style: TextStyle(
                fontSize: Dimensions.fontBodySmall * 0.85,
                fontWeight: FontWeight.w900,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
