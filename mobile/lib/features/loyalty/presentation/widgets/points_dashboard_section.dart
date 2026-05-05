import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';

class PointsDashboardSection extends ConsumerWidget {
  final WalletSummary wallet;
  final AppColors colors;
  final AppLocalizations l10n;

  static final Logger _logger = Logger('PointsDashboardSection');

  const PointsDashboardSection({
    super.key,
    required this.wallet,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(dashboardPointsProvider);

    return ListView(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSmartPointsCard(context),
        SizedBox(height: Dimensions.spacingExtraLarge),

        _buildRewardsEntryBanner(context),
        SizedBox(height: Dimensions.spacingExtraLarge),

        _buildSectionHeader(l10n.pointsHistory, () {
          _logger.info('Navigate to Points History');
          context.push(RoutePaths.pointsHistory);
        }),
        SizedBox(height: Dimensions.spacingMedium),
        pointsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            _logger.severe('Failed to load dashboard points', err, stack);
            return const SizedBox.shrink();
          },
          data: (paginated) => _buildPointsList(paginated.results, context),
        ),

        SizedBox(height: Dimensions.spacingExtraLarge * 3),
      ],
    );
  }

  /// Unified Premium Card with Smart Lifetime vs Spendable Separation
  Widget _buildSmartPointsCard(BuildContext context) {
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
          // Spendable Points Section (Primary Actionable Balance)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.spendablePoints,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  fontSize: Dimensions.fontBodyMedium,
                ),
              ),
              Container(
                padding: EdgeInsets.all(Dimensions.spacingSmall),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: colors.primary,
                  size: Dimensions.iconMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingTiny),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                wallet.spendablePoints.toString(),
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1 * 1.5,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              SizedBox(width: Dimensions.spacingSmall),
              Text(
                l10n.pts,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),

          SizedBox(height: Dimensions.spacingMedium),

          // Lifetime Points Section (Informational)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.spacingMedium,
              vertical: Dimensions.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: colors.iconGrey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: colors.textSecondary,
                  size: Dimensions.iconSmall,
                ),
                SizedBox(width: Dimensions.spacingTiny),
                Text(
                  '${l10n.lifetimePointsTitle} ${wallet.lifetimePoints} ${l10n.lifetimePointsDesc}',
                  style: TextStyle(
                    fontSize: Dimensions.fontBodySmall * 0.9,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Dimensions.spacingExtraLarge),

          // Interactive Tier Progress Box (Navigates to Roadmap)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _logger.info(
                  'User navigating to Gamified Track Screen via Tier Box',
                );
                context.push(RoutePaths.gamifiedTrack);
              },
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
              splashColor: colors.primary.withOpacity(0.1),
              highlightColor: colors.primary.withOpacity(0.05),
              child: Ink(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: colors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: colors.star,
                          size: Dimensions.iconMedium,
                        ),
                        SizedBox(width: Dimensions.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currentTier,
                                style: TextStyle(
                                  fontSize: Dimensions.fontBodySmall,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                wallet.nextMilestone?.title ?? "MAX TIER",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          l10n.viewRoadmap,
                          style: TextStyle(
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingTiny),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.primary,
                          size: Dimensions.iconMedium,
                        ),
                      ],
                    ),
                    if (wallet.nextMilestone != null) ...[
                      SizedBox(height: Dimensions.spacingMedium),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: wallet.nextMilestone!.progressPct / 100,
                          backgroundColor: colors.iconGrey.withOpacity(0.1),
                          color: colors.primary,
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingSmall),
                      Text(
                        '${wallet.nextMilestone!.requiredPoints - wallet.lifetimePoints} ${l10n.pointsToNextTier} ${wallet.nextMilestone!.title}',
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: Dimensions.spacingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _logger.info('User clicked: Buy Points');
                context.push(RoutePaths.buyPoints);
              },
              icon: Icon(
                Icons.add_shopping_cart_rounded,
                color: colors.surface,
                size: Dimensions.iconMedium,
              ),
              label: Text(
                l10n.buyPoints,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: Dimensions.fontTitleMedium,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.surface,
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek entry banner replacing the cluttered rewards list
  Widget _buildRewardsEntryBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _logger.info('Navigate to Rewards History');
        context.push(RoutePaths.rewardsHistory);
      },
      child: Container(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: colors.success.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.success.withOpacity(0.05),
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
                color: colors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: colors.success,
                size: Dimensions.iconLarge,
              ),
            ),
            SizedBox(width: Dimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myRewards,
                    style: TextStyle(
                      fontSize: Dimensions.fontTitleMedium,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    l10n.myRewardsDesc,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.success,
              size: Dimensions.iconMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Dimensions.fontTitleMedium,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
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

  Widget _buildPointsList(
    List<PointsTransaction> transactions,
    BuildContext context,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState(l10n.noTransactions, Icons.toll_rounded);
    }

    final String currentLocale = Localizations.localeOf(context).languageCode;

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
          final tx = transactions[index];
          final bool isEarn = tx.type == 'earn';
          final DateTime date =
              DateTime.tryParse(tx.createdAt)?.toLocal() ?? DateTime.now();

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.spacingLarge,
              vertical: Dimensions.spacingMedium,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingMedium),
                  decoration: BoxDecoration(
                    color: isEarn
                        ? colors.success.withOpacity(0.1)
                        : colors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarn ? Icons.add_rounded : Icons.remove_rounded,
                    color: isEarn ? colors.success : colors.warning,
                    size: Dimensions.iconMedium,
                  ),
                ),
                SizedBox(width: Dimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: Dimensions.fontBodyMedium,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingTiny),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                          currentLocale,
                        ).format(date),
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isEarn ? '+' : '-'}${tx.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: Dimensions.fontBodyLarge,
                    color: isEarn ? colors.success : colors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        child: Column(
          children: [
            Icon(
              icon,
              color: colors.iconGrey.withOpacity(0.3),
              size: Dimensions.iconLarge * 2,
            ),
            SizedBox(height: Dimensions.spacingSmall),
            Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
