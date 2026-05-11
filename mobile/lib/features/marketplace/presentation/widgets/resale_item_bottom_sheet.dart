import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/resale_models.dart';

class ResaleItemBottomSheet extends StatelessWidget {
  final ResaleItem item;
  final AppColors colors;
  final AppLocalizations l10n;

  static final Logger _logger = Logger('ResaleItemBottomSheet');

  const ResaleItemBottomSheet({
    super.key,
    required this.item,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final double savedAmount =
        item.pricing.fairValue - item.pricing.askingPrice;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: Dimensions.spacingLarge),
                  decoration: BoxDecoration(
                    color: colors.iconGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                ),
              ),

              // Title
              Text(
                l10n.dealSummary,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading2,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.spacingLarge),

              // Highlights Box (The Deal)
              Container(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      item.plan.name,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyLarge,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Text(
                      '${item.plan.daysLeft} ${l10n.daysLeft}',
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyMedium,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    Divider(height: Dimensions.spacingLarge * 1.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.fairValue,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: Dimensions.fontBodySmall,
                              ),
                            ),
                            Text(
                              '${item.pricing.fairValue.toStringAsFixed(0)} SAR',
                              style: TextStyle(
                                color: colors.iconGrey,
                                fontSize: Dimensions.fontBodyMedium,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.askingPrice,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: Dimensions.fontBodySmall,
                              ),
                            ),
                            Text(
                              '${item.pricing.askingPrice.toStringAsFixed(0)} SAR',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: Dimensions.fontHeading2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (savedAmount > 0) ...[
                      SizedBox(height: Dimensions.spacingMedium),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.spacingMedium,
                          vertical: Dimensions.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusPill,
                          ),
                        ),
                        child: Text(
                          '${l10n.youSaved} ${savedAmount.toStringAsFixed(0)} SAR!',
                          style: TextStyle(
                            color: colors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: Dimensions.fontBodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge),

              // Actions
              ElevatedButton(
                onPressed: () {
                  _logger.info('Proceed to checkout for item: ${item.id}');
                  context.pop(); // Close sheet
                  // TODO: Navigate to Resale Checkout (To be implemented next)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.continueToCheckout,
                  style: TextStyle(
                    fontSize: Dimensions.fontButton,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: Dimensions.spacingMedium),
              OutlinedButton(
                onPressed: () {
                  _logger.info('View Gym Details: ${item.gym.brandName}');
                  context.pop(); // Close sheet
                  context.push(RoutePaths.gymDetailsPath(item.id));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  side: BorderSide(
                    color: colors.iconGrey.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  l10n.viewGymDetails,
                  style: TextStyle(
                    fontSize: Dimensions.fontButton,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
