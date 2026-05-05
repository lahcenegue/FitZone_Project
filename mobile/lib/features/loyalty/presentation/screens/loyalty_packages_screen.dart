import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';

class LoyaltyPackagesScreen extends ConsumerStatefulWidget {
  const LoyaltyPackagesScreen({super.key});

  @override
  ConsumerState<LoyaltyPackagesScreen> createState() =>
      _LoyaltyPackagesScreenState();
}

class _LoyaltyPackagesScreenState extends ConsumerState<LoyaltyPackagesScreen> {
  LoyaltyPackage? _selectedPackage;
  bool _isProcessing = false;
  static final Logger _logger = Logger('LoyaltyPackagesScreen');

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final packagesAsync = ref.watch(loyaltyPackagesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.pointsPackages,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, l10n),
            Expanded(
              child: packagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildErrorState(colors, l10n, ref),
                data: (packages) => _buildPackagesList(packages, colors, l10n),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedPackage != null
          ? _buildCheckoutBar(colors, l10n)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(AppColors colors, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: colors.primary,
              size: Dimensions.iconLarge * 1.5,
            ),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            l10n.choosePackage,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: Dimensions.fontHeading2,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: Dimensions.spacingTiny),
          Text(
            l10n.levelUpRewards,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: Dimensions.fontBodyMedium,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList(
    List<LoyaltyPackage> packages,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: packages.length,
      separatorBuilder: (_, __) => SizedBox(height: Dimensions.spacingMedium),
      itemBuilder: (context, index) {
        final package = packages[index];
        final bool isSelected = _selectedPackage?.id == package.id;
        // Business Logic: Highlight the middle package as popular
        final bool isPopular = index == 1 && packages.length > 1;

        return _buildPackageCard(package, isSelected, isPopular, colors, l10n);
      },
    );
  }

  Widget _buildPackageCard(
    LoyaltyPackage package,
    bool isSelected,
    bool isPopular,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
        _logger.info('Selected package: ${package.name} (ID: ${package.id})');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.05)
              : colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.iconGrey.withValues(alpha: 0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.1)
                  : colors.shadow.withValues(alpha: 0.03),
              blurRadius: Dimensions.shadowBlurRadius,
              offset: Offset(0, Dimensions.shadowOffsetY),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio Button Equivalent
                Container(
                  width: Dimensions.iconLarge,
                  height: Dimensions.iconLarge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.iconGrey,
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: Dimensions.iconSmall,
                            height: Dimensions.iconSmall,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: Dimensions.spacingLarge),

                // Package Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: Dimensions.fontBodyLarge,
                          color: colors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingTiny),
                      Row(
                        children: [
                          Icon(
                            Icons.toll_rounded,
                            color: colors.warning, // Golden coin color
                            size: Dimensions.iconMedium,
                          ),
                          SizedBox(width: Dimensions.spacingTiny),
                          Text(
                            '${package.points} ${l10n.pts}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: Dimensions.fontHeading1,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  '${package.price.toStringAsFixed(2)}\n${l10n.sar}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: Dimensions.fontTitleMedium,
                    color: colors.primary,
                  ),
                ),
              ],
            ),

            // Popular Badge
            if (isPopular)
              Positioned(
                top: -Dimensions.spacingLarge - Dimensions.spacingSmall,
                right: Dimensions.spacingMedium,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingTiny,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  child: Text(
                    l10n.mostPopular,
                    style: TextStyle(
                      color: colors.surface,
                      fontWeight: FontWeight.w800,
                      fontSize: Dimensions.fontBodySmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(AppColors colors, AppLocalizations l10n) {
    if (_selectedPackage == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: Dimensions.spacingLarge,
        right: Dimensions.spacingLarge,
        top: Dimensions.spacingMedium,
        bottom: Dimensions.spacingExtraLarge,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: Dimensions.spacingExtraLarge,
            offset: Offset(0, -Dimensions.spacingSmall),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalAmount,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_selectedPackage!.price.toStringAsFixed(2)} ${l10n.sar}',
                  style: TextStyle(
                    fontSize: Dimensions.fontTitleLarge,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: Dimensions.screenWidth * 0.45,
              height: Dimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: Dimensions.iconMedium,
                        height: Dimensions.iconMedium,
                        child: CircularProgressIndicator(
                          color: colors.surface,
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text(
                        l10n.payAmount(
                          _selectedPackage!.price.toStringAsFixed(2),
                        ),
                        style: TextStyle(
                          fontSize: Dimensions.fontButton,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    AppColors colors,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: Dimensions.iconLarge * 3,
            color: colors.error.withValues(alpha: 0.5),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            l10n.errorLoadingDetails,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Dimensions.spacingLarge),
          ElevatedButton(
            onPressed: () => ref.invalidate(loyaltyPackagesProvider),
            child: Text(l10n.retryButton),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase() async {
    if (_selectedPackage == null) return;

    setState(() => _isProcessing = true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    try {
      final apiService = ref.read(loyaltyApiServiceProvider);

      // Defaulting to "mock" gateway as per API requirements
      final bool success = await apiService.purchasePoints(
        packageId: _selectedPackage!.id,
        gateway: 'mock',
      );

      if (success && mounted) {
        // Force refresh the wallet and transactions to show new data
        ref.invalidate(loyaltyWalletProvider);
        ref.invalidate(dashboardTransactionsProvider);
        ref.invalidate(loyaltyRoadmapProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.purchaseSuccessful),
            backgroundColor: ref.read(appThemeProvider).success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.pop(); // Go back to the dashboard
      }
    } catch (e, stackTrace) {
      _logger.severe('Purchase failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOops),
            backgroundColor: ref.read(appThemeProvider).error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
