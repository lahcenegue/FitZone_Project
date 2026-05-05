import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../widgets/financial_dashboard_section.dart';
import '../widgets/points_dashboard_section.dart';

class LoyaltyDashboardScreen extends ConsumerWidget {
  const LoyaltyDashboardScreen({super.key});

  static final Logger _logger = Logger('LoyaltyDashboardScreen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = ref.watch(appThemeProvider);
    final l10n = AppLocalizations.of(context)!;

    final walletAsync = ref.watch(loyaltyWalletProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(
            l10n.walletAndRewards,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: colors.surface,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: colors.textPrimary),
          bottom: TabBar(
            indicatorColor: colors.primary,
            indicatorWeight: 3.0,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: Dimensions.fontBodyLarge,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: Dimensions.fontBodyMedium,
            ),
            tabs: [
              Tab(text: l10n.financialWallet),
              Tab(text: l10n.pointsWallet),
            ],
          ),
        ),
        body: walletAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            _logger.severe('Failed to load wallet data', err, stack);
            return _buildErrorUI(colors, l10n, ref);
          },
          data: (wallet) => TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(loyaltyWalletProvider);
                  ref.invalidate(dashboardTransactionsProvider);
                },
                child: FinancialDashboardSection(
                  wallet: wallet,
                  colors: colors,
                  l10n: l10n,
                ),
              ),

              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(loyaltyWalletProvider);
                  // FIX: Invalidate all relevant points/rewards providers
                  ref.invalidate(dashboardRewardsProvider);
                  ref.invalidate(dashboardPointsProvider);
                  ref.invalidate(consumedRewardsProvider);
                },
                child: PointsDashboardSection(
                  wallet: wallet,
                  colors: colors,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI(AppColors colors, AppLocalizations l10n, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: Dimensions.iconLarge * 3,
            color: colors.error.withOpacity(0.5),
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
            onPressed: () => ref.invalidate(loyaltyWalletProvider),
            child: Text(l10n.retryButton),
          ),
        ],
      ),
    );
  }
}
