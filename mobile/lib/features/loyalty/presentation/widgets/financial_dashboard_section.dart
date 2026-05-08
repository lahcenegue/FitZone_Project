import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';

class FinancialDashboardSection extends ConsumerWidget {
  final WalletSummary wallet;
  final AppColors colors;
  final AppLocalizations l10n;

  static final Logger _logger = Logger('FinancialDashboardSection');

  const FinancialDashboardSection({
    super.key,
    required this.wallet,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPremiumVirtualCard(context),
        SizedBox(height: Dimensions.spacingExtraLarge),

        // ARCHITECTURE FIX: Cleaned Quick Actions - Removed Redundant Bank Button
        _buildQuickActionsRow(context),
        SizedBox(height: Dimensions.spacingExtraLarge),

        // ARCHITECTURE FIX: Smart Banner that adapts to Add/Edit states
        _buildSmartBankBanner(context),

        SizedBox(height: Dimensions.spacingExtraLarge * 2),
      ],
    );
  }

  Widget _buildPremiumVirtualCard(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.textPrimary.withValues(alpha: 0.9),
            colors.textPrimary.withValues(alpha: 0.7),
          ],
          begin: isRTL ? Alignment.topRight : Alignment.topLeft,
          end: isRTL ? Alignment.bottomLeft : Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // ARCHITECTURE FIX: ClipRRect ensures the watermark does not break card boundaries
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        child: Stack(
          children: [
            // Elegant Watermark correctly positioned
            Positioned(
              right: isRTL ? null : -5,
              left: isRTL ? -5 : null,
              bottom: -5,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: Dimensions.iconLarge * 6,
                color: colors.surface.withValues(alpha: 0.04),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: colors.surface.withValues(alpha: 0.8),
                        size: Dimensions.iconMedium,
                      ),
                      SizedBox(width: Dimensions.spacingSmall),
                      Text(
                        l10n.fiatBalance,
                        style: TextStyle(
                          color: colors.surface.withValues(alpha: 0.9),
                          fontSize: Dimensions.fontBodyLarge,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge * 1.2),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          wallet.fiatBalance.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading1 * 2,
                            fontWeight: FontWeight.w900,
                            color: colors.surface,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingSmall),
                        Text(
                          l10n.currency,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.w700,
                            color: colors.surface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clean, centralized actions for money operations only
  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionItem(
          icon: Icons.payments_rounded,
          label: l10n.withdrawFunds,
          color: wallet.fiatBalance > 0 ? colors.success : colors.iconGrey,
          onTap: () {
            if (wallet.fiatBalance > 0) {
              _logger.info('Navigate to Withdraw Screen');
              context.push(RoutePaths.withdraw);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.insufficientBalance),
                  backgroundColor: colors.warning,
                ),
              );
            }
          },
        ),
        SizedBox(
          width: Dimensions.spacingExtraLarge * 2,
        ), // Spacing between the two actions
        _buildActionItem(
          icon: Icons.receipt_long_rounded,
          label: l10n.quickActionHistory,
          color: colors.warning,
          onTap: () {
            _logger.info('Navigate to Financial Transactions History');
            context.push(RoutePaths.transactionsHistory);
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: Dimensions.iconLarge),
          ),
          SizedBox(height: Dimensions.spacingSmall),
          Text(
            label,
            style: TextStyle(
              fontSize: Dimensions.fontBodySmall,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Smart banner: Adapts its text and UI based on whether an account exists
  Widget _buildSmartBankBanner(BuildContext context) {
    final BankAccount? bankAccount = wallet.bankAccount;
    final bool hasBank = bankAccount != null;

    return GestureDetector(
      onTap: () => context.push(RoutePaths.bankAccount),
      child: Container(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.spacingMedium),
              decoration: BoxDecoration(
                color: hasBank
                    ? colors.success.withValues(alpha: 0.1)
                    : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: hasBank ? colors.success : colors.primary,
                size: Dimensions.iconLarge,
              ),
            ),
            SizedBox(width: Dimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasBank ? l10n.editBankAccount : l10n.addBankAccount,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: hasBank ? colors.success : colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    hasBank
                        ? '${bankAccount.bankName} (${bankAccount.accountNumber})'
                        : l10n.manageYourBank,
                    style: TextStyle(
                      fontSize: hasBank
                          ? Dimensions.fontTitleMedium
                          : Dimensions.fontBodySmall,
                      fontWeight: hasBank ? FontWeight.w900 : FontWeight.w600,
                      color: hasBank
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.iconGrey,
              size: Dimensions.iconMedium,
            ),
          ],
        ),
      ),
    );
  }
}
