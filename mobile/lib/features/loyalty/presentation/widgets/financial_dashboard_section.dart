import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import 'transaction_item_card.dart';

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
    // Watches the limited provider (5 transactions max) from the backend
    final transactionsAsync = ref.watch(dashboardTransactionsProvider);

    return ListView(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildUnifiedFiatCard(context, wallet.bankAccount),
        SizedBox(height: Dimensions.spacingExtraLarge),

        _buildTransactionsHeader(context),
        SizedBox(height: Dimensions.spacingMedium),

        transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            _logger.severe('Error loading transactions', error, stack);
            return const SizedBox.shrink();
          },
          data: (paginatedData) =>
              _buildTransactionsList(paginatedData.results),
        ),

        SizedBox(height: Dimensions.spacingExtraLarge * 3),
      ],
    );
  }

  Widget _buildUnifiedFiatCard(BuildContext context, BankAccount? bankAccount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: Dimensions.spacingExtraLarge,
            offset: Offset(0, Dimensions.spacingMedium),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.fiatBalance,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  fontSize: Dimensions.fontBodyMedium,
                ),
              ),
              Container(
                padding: EdgeInsets.all(Dimensions.spacingSmall),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colors.success,
                  size: Dimensions.iconMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingTiny),
          Text(
            '${wallet.fiatBalance.toStringAsFixed(2)} ${l10n.sar}',
            style: TextStyle(
              fontSize: Dimensions.fontHeading1 * 1.5,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),

          if (bankAccount != null)
            Container(
              padding: EdgeInsets.all(Dimensions.spacingMedium),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: colors.textSecondary,
                        size: Dimensions.iconMedium,
                      ),
                      SizedBox(width: Dimensions.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.linkedAccount,
                              style: TextStyle(
                                fontSize: Dimensions.fontBodySmall,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              '${bankAccount.bankName} (${bankAccount.accountNumber})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _logger.info('User initiated edit bank account');
                          context.push(RoutePaths.bankAccount);
                        },
                        icon: Icon(
                          Icons.edit_rounded,
                          color: colors.primary,
                          size: Dimensions.iconMedium,
                        ),
                        splashRadius: Dimensions.spacingLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingMedium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: wallet.fiatBalance > 0
                          ? () {
                              _logger.info('User initiated withdrawal');
                              context.push(RoutePaths.withdraw);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusPill,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: Dimensions.spacingMedium,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.withdrawFunds,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: Dimensions.fontTitleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingMedium,
                vertical: Dimensions.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.addBankAccount,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyMedium,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _logger.info('User clicked: Add bank account');
                      context.push(RoutePaths.bankAccount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary.withOpacity(0.1),
                      foregroundColor: colors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.addBankAccount,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.transactionsHistory,
          style: TextStyle(
            fontSize: Dimensions.fontTitleMedium,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {
            _logger.info('User clicked: See all transactions');
            context.push(RoutePaths.transactionsHistory);
          },
          child: Text(
            l10n.seeAll,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(List<FinancialTransaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          child: Text(
            l10n.noTransactions,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colors.iconGrey.withOpacity(0.1),
          indent: Dimensions.spacingExtraLarge * 2,
        ),
        itemBuilder: (context, index) {
          return TransactionItemCard(
            transaction: transactions[index],
            colors: colors,
            l10n: l10n,
          );
        },
      ),
    );
  }
}
