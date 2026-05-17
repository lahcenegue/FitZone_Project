import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/custom_empty_state.dart';
import '../../../../core/presentation/widgets/premium_search_bar.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/resale_item_bottom_sheet.dart';
import '../widgets/resale_item_card.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger('MarketplaceScreen');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      ref.read(marketplaceControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;

    final marketplaceState = ref.watch(marketplaceControllerProvider);
    final filterState = ref.watch(marketplaceFilterProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.marketplaceTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.fontTitleLarge,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            Dimensions.searchBarHeight + Dimensions.spacingMedium,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Dimensions.spacingLarge,
              0,
              Dimensions.spacingLarge,
              Dimensions.spacingMedium,
            ),
            child: PremiumSearchBar(
              colors: colors,
              hintText: l10n.searchResale,
              initialQuery: filterState.query ?? '',
              activeFilterCount: filterState.activeFilterCount,
              onSearchSubmitted: (query) {
                _logger.info('Search query submitted: $query');
                ref
                    .read(marketplaceFilterProvider.notifier)
                    .updateFilters(filterState.copyWith(query: query));
              },
              onClearTapped: () {
                _logger.info('Search query cleared');
                ref
                    .read(marketplaceFilterProvider.notifier)
                    .updateFilters(filterState.copyWith(clearQuery: true));
              },
              onFilterTapped: () {
                _logger.info('Navigating to Marketplace Filters');
                context.push(RoutePaths.marketplaceFilters);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom:
            false, // ARCHITECTURE FIX: We handle bottom padding manually for extendBody
        child: marketplaceState.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
          error: (error, stack) {
            _logger.severe('Failed to load marketplace data', error, stack);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colors.error,
                    size: Dimensions.iconLarge * 2,
                  ),
                  SizedBox(height: Dimensions.spacingMedium),
                  Text(
                    l10n.errorOops,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(marketplaceControllerProvider.notifier)
                          .refresh();
                    },
                    child: Text(l10n.retryButton),
                  ),
                ],
              ),
            );
          },
          data: (state) {
            if (state.items.isEmpty) {
              return CustomEmptyState(
                message: l10n.noResaleItems,
                icon: Icons.storefront_outlined,
                colors: colors,
              );
            }

            return RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: () =>
                  ref.read(marketplaceControllerProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  top: Dimensions.spacingMedium,
                  left: Dimensions.spacingLarge,
                  right: Dimensions.spacingLarge,
                  // ARCHITECTURE FIX: Precise Pixel-Perfect Calculation for floating dock clearance
                  bottom: safeArea.bottom + (Dimensions.buttonHeight * 1.6),
                ),
                itemCount: state.items.length + (state.isLoadMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Dimensions.spacingMedium,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      ),
                    );
                  }

                  final item = state.items[index];
                  return ResaleItemCard(
                    item: item,
                    colors: colors,
                    l10n: l10n,
                    onTap: () {
                      _logger.info(
                        'Opening bottom sheet for resale item: ${item.id}',
                      );
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ResaleItemBottomSheet(
                          item: item,
                          colors: colors,
                          l10n: l10n,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
