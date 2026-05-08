import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import 'reward_success_dialog.dart';

class TrackRewardSheet extends ConsumerStatefulWidget {
  final LoyaltyMilestone milestone;
  final UserMilestoneData? userMilestoneData;
  final int currentLifetimePoints;
  final AppColors colors;
  final AppLocalizations l10n;

  const TrackRewardSheet({
    super.key,
    required this.milestone,
    required this.userMilestoneData,
    required this.currentLifetimePoints,
    required this.colors,
    required this.l10n,
  });

  @override
  ConsumerState<TrackRewardSheet> createState() => _TrackRewardSheetState();
}

class _TrackRewardSheetState extends ConsumerState<TrackRewardSheet> {
  static final Logger _logger = Logger('TrackRewardSheet');
  bool _isLoading = false;

  Future<void> _handleClaimReward() async {
    if (widget.userMilestoneData == null ||
        widget.userMilestoneData!.userMilestoneId == null)
      return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      await apiService.claimReward(
        userMilestoneId: widget.userMilestoneData!.userMilestoneId!,
      );

      _logger.info('Reward claimed successfully: ${widget.milestone.id}');

      ref.invalidate(loyaltyRoadmapProvider);
      ref.invalidate(loyaltyWalletProvider);
      ref.invalidate(allUserMilestonesProvider);
      ref.invalidate(dashboardRewardsProvider);
      ref.invalidate(rewardsSummaryProvider);

      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => RewardSuccessDialog(
            milestone: widget.milestone,
            colors: widget.colors,
            l10n: widget.l10n,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to claim reward', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.errorOops),
            backgroundColor: widget.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.userMilestoneData?.status ?? 'locked';
    final bool isLocked = status == 'locked';
    final bool isUnlocked = status == 'unlocked';
    final bool isClaimed = status == 'claimed' || status == 'consumed';

    final int pointsRemaining = isLocked
        ? (widget.milestone.requiredLifetimePoints -
              widget.currentLifetimePoints)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge * 2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimensions.spacingExtraLarge,
        Dimensions.spacingMedium,
        Dimensions.spacingExtraLarge,
        Dimensions.spacingExtraLarge * 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: Dimensions.spacingExtraLarge * 2,
            height: Dimensions.spacingTiny,
            decoration: BoxDecoration(
              color: widget.colors.iconGrey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            ),
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.milestone.title.toUpperCase(),
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.w900,
                  color: widget.colors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  radius: Dimensions.iconMedium,
                  backgroundColor: widget.colors.surface,
                  child: Icon(
                    Icons.close_rounded,
                    size: Dimensions.iconMedium,
                    color: widget.colors.iconGrey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),

          Text(
            isLocked
                ? widget.l10n.trackLockedTitle
                : (isUnlocked
                      ? widget.l10n.trackUnlockedTitle
                      : widget.l10n.trackClaimedTitle),
            style: TextStyle(
              fontSize: Dimensions.fontHeading1,
              fontWeight: FontWeight.w900,
              color: widget.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingSmall),
          Text(
            isLocked
                ? widget.l10n.trackLockedDesc
                : (isUnlocked
                      ? widget.l10n.trackUnlockedDesc
                      : widget.l10n.trackClaimedDesc),
            style: TextStyle(
              fontSize: Dimensions.fontBodyLarge,
              color: widget.colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),

          if (widget.milestone.reward != null)
            _buildSmartTeaser(widget.milestone.reward!),

          SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

          if (isLocked)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: Dimensions.spacingMedium),
              decoration: BoxDecoration(
                color: widget.colors.iconGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    color: widget.colors.iconGrey,
                    size: Dimensions.iconMedium,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    '$pointsRemaining ${widget.l10n.pointsNeededToUnlock}',
                    style: TextStyle(
                      fontSize: Dimensions.fontTitleMedium,
                      fontWeight: FontWeight.w900,
                      color: widget.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (isClaimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(RoutePaths.rewardsHistory);
                },
                icon: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: widget.colors.primary,
                ),
                label: Text(
                  widget.l10n.goToWalletBtn,
                  style: TextStyle(
                    fontSize: Dimensions.fontTitleMedium,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.surface,
                  foregroundColor: widget.colors.primary,
                  side: BorderSide(color: widget.colors.primary, width: 2),
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingMedium * 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleClaimReward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.primary,
                  foregroundColor: widget.colors.surface,
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingMedium * 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: Dimensions.iconMedium,
                        width: Dimensions.iconMedium,
                        child: CircularProgressIndicator(
                          color: widget.colors.surface,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.l10n.claimRewardBtn,
                        style: TextStyle(
                          fontSize: Dimensions.fontTitleMedium,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmartTeaser(LoyaltyReward reward) {
    if (reward.actionType == 'sys_roaming' ||
        reward.actionType == 'sys_extension' ||
        reward.couponType == null) {
      return _buildPremiumServiceTeaser(reward);
    } else {
      return _buildResponsiveCouponTicket(reward);
    }
  }

  /// ARCHITECTURE FIX: Clean, eye-friendly flat design for services without harsh gradients
  Widget _buildPremiumServiceTeaser(LoyaltyReward reward) {
    final bool isRoaming = reward.actionType == 'sys_roaming';
    final IconData serviceIcon = isRoaming
        ? Icons.directions_run_rounded
        : Icons.event_available_rounded;
    final Color serviceColor = isRoaming
        ? widget.colors.primary
        : widget.colors.success;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(
          color: widget.colors.iconGrey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.03),
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
              color: serviceColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              serviceIcon,
              color: serviceColor,
              size: Dimensions.iconLarge * 1.5,
            ),
          ),
          SizedBox(width: Dimensions.spacingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: Dimensions.fontHeading3,
                    fontWeight: FontWeight.w900,
                    color: widget.colors.textPrimary,
                  ),
                ),
                if (widget.milestone.description.isNotEmpty) ...[
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    widget.milestone.description,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: widget.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ARCHITECTURE FIX: Clean, minimalist ticket using ONLY AppColors with very low opacity
  Widget _buildResponsiveCouponTicket(LoyaltyReward reward) {
    Color ticketColor;
    IconData ticketIcon;
    String displayValue;

    // Mapping using AppColors strictly
    switch (reward.couponType) {
      case 'free_shipping':
        ticketColor = widget.colors.success;
        ticketIcon = Icons.local_shipping_rounded;
        displayValue = widget.l10n.freeShipping;
        break;
      case 'bogo':
        ticketColor = widget.colors.primary;
        ticketIcon = Icons.join_inner_rounded;
        displayValue = widget.l10n.bogoDiscount;
        break;
      case 'free_item':
        ticketColor = widget.colors.warning;
        ticketIcon = Icons.card_giftcard_rounded;
        displayValue = widget.l10n.freeItem;
        break;
      case 'percentage':
        ticketColor = widget.colors.warning;
        ticketIcon = Icons.percent_rounded;
        displayValue = '${reward.discountValue?.toStringAsFixed(0) ?? 0}%';
        break;
      case 'fixed_amount':
        ticketColor = widget.colors.primary;
        ticketIcon = Icons.attach_money_rounded;
        displayValue =
            '${reward.discountValue?.toStringAsFixed(0) ?? 0} ${widget.l10n.currency}';
        break;
      default:
        ticketColor = widget.colors.primary;
        ticketIcon = Icons.local_offer_rounded;
        displayValue = reward.name;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(
          color: widget.colors.iconGrey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Ticket Stub (Very Soft Background)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingLarge,
                vertical: Dimensions.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: ticketColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 0
                        : Dimensions.borderRadiusLarge - 2,
                  ),
                  right: Radius.circular(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? Dimensions.borderRadiusLarge - 2
                        : 0,
                  ),
                ),
              ),
              child: Center(
                child: Icon(
                  ticketIcon,
                  color: ticketColor,
                  size: Dimensions.iconLarge * 1.5,
                ),
              ),
            ),

            // Dashed Cutline
            SizedBox(
              width: 2,
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  15,
                  (_) => SizedBox(
                    width: 2,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.colors.iconGrey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right Ticket Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: Dimensions.fontHeading2,
                          fontWeight: FontWeight.w900,
                          color: ticketColor,
                        ),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Text(
                      reward.name,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyMedium,
                        fontWeight: FontWeight.w700,
                        color: widget.colors.textPrimary,
                      ),
                    ),
                    if (widget.milestone.description.isNotEmpty) ...[
                      SizedBox(height: Dimensions.spacingTiny),
                      Text(
                        widget.milestone.description,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          color: widget.colors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
