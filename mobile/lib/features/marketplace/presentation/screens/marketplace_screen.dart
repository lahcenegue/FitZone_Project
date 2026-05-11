import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/custom_empty_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/resale_item_card.dart';
import '../widgets/resale_item_bottom_sheet.dart';

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
    final marketplaceState = ref.watch(marketplaceControllerProvider);

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
      ),
      body: SafeArea(
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
                  top: Dimensions.spacingLarge,
                  left: Dimensions.spacingLarge,
                  right: Dimensions.spacingLarge,
                  // ARCHITECTURE FIX: Extra padding at bottom to prevent floating nav bar intersection
                  bottom: Dimensions.spacingExtraLarge * 4,
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
