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

class PointsDashboardSection extends ConsumerStatefulWidget {
  final WalletSummary wallet;
  final AppColors colors;
  final AppLocalizations l10n;

  const PointsDashboardSection({
    super.key,
    required this.wallet,
    required this.colors,
    required this.l10n,
  });

  @override
  ConsumerState<PointsDashboardSection> createState() =>
      _PointsDashboardSectionState();
}

class _PointsDashboardSectionState extends ConsumerState<PointsDashboardSection>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('PointsDashboardSection');
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.wallet.unlockedRewardsCount > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PointsDashboardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallet.unlockedRewardsCount > 0 &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.wallet.unlockedRewardsCount == 0 &&
        _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ARCHITECTURE FIX: Safely extract the current level from the roadmap
    final roadmapAsync = ref.watch(loyaltyRoadmapProvider);
    final String currentLevelTitle = roadmapAsync.maybeWhen(
      data: (data) => data.metaProgress.currentMilestoneTitle,
      orElse: () => '...',
    );

    return ListView(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPremiumVirtualCard(currentLevelTitle),
        SizedBox(height: Dimensions.spacingExtraLarge),

        _buildQuickActionsGrid(context),
        SizedBox(height: Dimensions.spacingExtraLarge),

        _buildGamifiedTrackPortal(context),

        // ARCHITECTURE FIX: Removed the entire Points History List logic
        // to respect SRP (Single Responsibility Principle) and maintain a Clean UI.
        SizedBox(height: Dimensions.spacingExtraLarge * 2),
      ],
    );
  }

  /// Masterpiece: Softened Virtual Card with beautifully integrated watermark
  Widget _buildPremiumVirtualCard(String currentLevelTitle) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.colors.primary.withValues(alpha: 0.8),
            widget.colors.primary.withValues(alpha: 0.6),
          ],
          begin: isRTL ? Alignment.topRight : Alignment.topLeft,
          end: isRTL ? Alignment.bottomLeft : Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.colors.primary.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        child: Stack(
          children: [
            Positioned(
              right: isRTL ? null : 0,
              left: isRTL ? 0 : null,
              bottom: -20,
              child: Icon(
                Icons.toll_rounded,
                size: Dimensions.iconLarge * 6,
                color: widget.colors.surface.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: widget.colors.surface.withValues(alpha: 0.8),
                            size: Dimensions.iconMedium,
                          ),
                          SizedBox(width: Dimensions.spacingSmall),
                          Text(
                            widget.l10n.virtualCardTitle,
                            style: TextStyle(
                              color: widget.colors.surface.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: Dimensions.fontBodyMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.spacingMedium,
                          vertical: Dimensions.spacingTiny,
                        ),
                        decoration: BoxDecoration(
                          color: widget.colors.surface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusPill,
                          ),
                          border: Border.all(
                            color: widget.colors.surface.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          currentLevelTitle.toUpperCase(),
                          style: TextStyle(
                            color: widget.colors.surface,
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
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
                          widget.wallet.spendablePoints.toString(),
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading1 * 2,
                            fontWeight: FontWeight.w900,
                            color: widget.colors.surface,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingSmall),
                        Text(
                          widget.l10n.pts,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.w700,
                            color: widget.colors.surface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge),
                  Row(
                    children: [
                      Icon(
                        Icons.military_tech_rounded,
                        color: widget.colors.star,
                        size: Dimensions.iconMedium,
                      ),
                      SizedBox(width: Dimensions.spacingSmall),
                      Expanded(
                        child: Text(
                          '${widget.l10n.lifetimePointsTitle} ${widget.wallet.lifetimePoints}',
                          style: TextStyle(
                            color: widget.colors.surface.withValues(alpha: 0.9),
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: widget.l10n.lifetimePointsDesc,
                        triggerMode: TooltipTriggerMode.tap,
                        decoration: BoxDecoration(
                          color: widget.colors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          color: widget.colors.textPrimary,
                          fontSize: Dimensions.fontBodyMedium,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: Dimensions.iconSmall,
                          color: widget.colors.surface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionItem(
          icon: Icons.add_shopping_cart_rounded,
          label: widget.l10n.quickActionBuy,
          color: widget.colors.primary,
          onTap: () {
            _logger.info('Navigate to Buy Points');
            context.push(RoutePaths.buyPoints);
          },
        ),
        _buildActionItem(
          icon: Icons.card_giftcard_rounded,
          label: widget.l10n.quickActionRewards,
          color: widget.colors.success,
          onTap: () {
            _logger.info('Navigate to Rewards Wallet');
            context.push(RoutePaths.rewardsHistory);
          },
        ),
        _buildActionItem(
          icon: Icons.history_rounded,
          label: widget.l10n.quickActionHistory,
          color: widget.colors.warning,
          onTap: () {
            _logger.info('Navigate to Points History');
            context.push(RoutePaths.pointsHistory);
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
              color: widget.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.colors.iconGrey.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.shadow.withValues(alpha: 0.03),
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
              color: widget.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamifiedTrackPortal(BuildContext context) {
    final int unlockedCount = widget.wallet.unlockedRewardsCount;

    return GestureDetector(
      onTap: () {
        _logger.info('Navigate to Gamified Track');
        context.push(RoutePaths.gamifiedTrack);
      },
      child: Container(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: unlockedCount > 0
                ? widget.colors.error.withValues(alpha: 0.3)
                : widget.colors.iconGrey.withValues(alpha: 0.1),
            width: unlockedCount > 0 ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: unlockedCount > 0
                  ? widget.colors.error.withValues(alpha: 0.05)
                  : widget.colors.shadow.withValues(alpha: 0.03),
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
                color: widget.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              ),
              child: Icon(
                Icons.map_rounded,
                color: widget.colors.primary,
                size: Dimensions.iconLarge,
              ),
            ),
            SizedBox(width: Dimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.goToTrackBannerTitle,
                    style: TextStyle(
                      fontSize: Dimensions.fontTitleMedium,
                      fontWeight: FontWeight.w900,
                      color: widget.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  if (unlockedCount > 0)
                    Text(
                      widget.l10n.unlockedRewardsBadge(
                        unlockedCount.toString(),
                      ),
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        fontWeight: FontWeight.bold,
                        color: widget.colors.error,
                      ),
                    )
                  else
                    Text(
                      widget.l10n.goToTrackBannerSubtitle,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        color: widget.colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (unlockedCount > 0)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: EdgeInsets.all(Dimensions.spacingSmall),
                  decoration: BoxDecoration(
                    color: widget.colors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unlockedCount.toString(),
                    style: TextStyle(
                      color: widget.colors.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: Dimensions.fontBodySmall,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.colors.iconGrey,
                size: Dimensions.iconMedium,
              ),
          ],
        ),
      ),
    );
  }
}
