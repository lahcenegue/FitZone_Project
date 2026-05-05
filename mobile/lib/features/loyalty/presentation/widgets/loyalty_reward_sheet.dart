import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../../../../core/routing/app_router.dart';

class LoyaltyRewardSheet extends ConsumerStatefulWidget {
  final LoyaltyMilestone milestone;
  final UserMilestone? userMilestone;
  final bool isUnlocked;
  final bool isFromWallet; // Key variable for Separation of Concerns
  final AppColors colors;
  final AppLocalizations l10n;

  const LoyaltyRewardSheet({
    super.key,
    required this.milestone,
    required this.userMilestone,
    required this.isUnlocked,
    this.isFromWallet = false, // Defaults to false (Gamified Track)
    required this.colors,
    required this.l10n,
  });

  @override
  ConsumerState<LoyaltyRewardSheet> createState() => _LoyaltyRewardSheetState();
}

class _LoyaltyRewardSheetState extends ConsumerState<LoyaltyRewardSheet> {
  static final Logger _logger = Logger('LoyaltyRewardSheet');
  bool _isLoading = false;

  Future<void> _handleClaimReward() async {
    if (widget.userMilestone == null) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      await apiService.claimReward(userMilestoneId: widget.userMilestone!.id);

      _logger.info('Reward claimed successfully: ${widget.milestone.id}');

      ref.invalidate(allUserMilestonesProvider);
      ref.invalidate(dashboardRewardsProvider);
      ref.invalidate(rewardsSummaryProvider);
      ref.invalidate(loyaltyWalletProvider);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(widget.l10n.rewardClaimedSuccess, widget.colors.success);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to claim reward', e, stackTrace);
      if (mounted) _showSnackBar(widget.l10n.errorOops, widget.colors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleUseReward() {
    if (widget.userMilestone == null || widget.milestone.reward == null) return;

    final reward = widget.milestone.reward!;

    // Per Rule 4: UI cannot be built without Backend API readiness.
    // QR_VERIFIED and IMMEDIATE require secure tokens and active subscriptions APIs.
    if (reward.fulfillmentType == 'QR_VERIFIED' ||
        reward.fulfillmentType == 'IMMEDIATE') {
      _logger.warning(
        'Backend APIs for QR and Subscriptions are pending. Action blocked.',
      );
      return;
    }

    Navigator.pop(context);

    if (reward.fulfillmentType == 'CONTEXTUAL' ||
        reward.fulfillmentType == 'DELIVERY') {
      if (reward.actionRoute != null && reward.actionRoute!.isNotEmpty) {
        context.push(reward.actionRoute!);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isClaimed = widget.userMilestone?.isClaimed ?? false;
    final bool isConsumed = widget.userMilestone?.isConsumed ?? false;

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
                widget.l10n.rewardDetails,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.w800,
                  color: widget.colors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
            widget.milestone.reward?.name ?? widget.milestone.title,
            style: TextStyle(
              fontSize: Dimensions.fontHeading1,
              fontWeight: FontWeight.w900,
              color: widget.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingSmall),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.spacingMedium,
              vertical: Dimensions.spacingTiny,
            ),
            decoration: BoxDecoration(
              color: widget.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            ),
            child: Text(
              '${widget.milestone.requiredLifetimePoints} ${widget.l10n.pts}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: widget.colors.primary,
                fontSize: Dimensions.fontBodyMedium,
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

          Container(
            padding: EdgeInsets.all(Dimensions.spacingExtraLarge * 1.5),
            decoration: BoxDecoration(
              color: widget.isUnlocked
                  ? (isConsumed
                        ? widget.colors.iconGrey.withValues(alpha: 0.1)
                        : widget.colors.primary.withValues(alpha: 0.1))
                  : widget.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isUnlocked
                    ? (isConsumed
                          ? widget.colors.iconGrey.withValues(alpha: 0.3)
                          : widget.colors.primary.withValues(alpha: 0.3))
                    : widget.colors.iconGrey.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: Icon(
              widget.isUnlocked
                  ? (isConsumed
                        ? Icons.check_circle_rounded
                        : Icons.redeem_rounded)
                  : Icons.lock_rounded,
              size: Dimensions.iconLarge * 3,
              color: widget.isUnlocked
                  ? (isConsumed
                        ? widget.colors.iconGrey
                        : widget.colors.primary)
                  : widget.colors.iconGrey.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

          Text(
            widget.milestone.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Dimensions.fontTitleMedium,
              fontWeight: FontWeight.w700,
              color: widget.colors.textPrimary,
              height: 1.4,
            ),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            widget.isUnlocked
                ? (isConsumed
                      ? widget.l10n.consumedDesc
                      : (isClaimed
                            ? widget.l10n.claimedDesc
                            : widget.l10n.unlockedDesc))
                : widget.l10n.lockedDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Dimensions.fontBodyMedium,
              color: widget.colors.textSecondary,
              height: 1.3,
            ),
          ),
          SizedBox(height: Dimensions.spacingExtraLarge * 2),

          _buildContextualActionButton(isClaimed, isConsumed),
        ],
      ),
    );
  }

  Widget _buildContextualActionButton(bool isClaimed, bool isConsumed) {
    if (!widget.isUnlocked) {
      return _buildButtonWrapper(
        text: widget.l10n.lockedBtn,
        color: widget.colors.surface,
        textColor: widget.colors.iconGrey,
        onPressed: null,
      );
    }

    if (isConsumed) {
      return _buildButtonWrapper(
        text: widget.l10n.consumedBtn,
        color: widget.colors.iconGrey.withValues(alpha: 0.1),
        textColor: widget.colors.iconGrey,
        onPressed: null,
      );
    }

    // Logic: If opened from Gamified Track
    if (!widget.isFromWallet) {
      if (isClaimed) {
        return _buildButtonWrapper(
          text: widget.l10n.claimedDesc, // Informative only
          color: widget.colors.surface,
          textColor: widget.colors.primary,
          onPressed: () {
            Navigator.pop(context);
            context.push(RoutePaths.rewardsHistory);
          },
          icon: Icons.account_balance_wallet_rounded,
        );
      } else {
        return _buildButtonWrapper(
          text: widget.l10n.claimRewardBtn,
          color: widget.colors.primary,
          textColor: widget.colors.surface,
          onPressed: _isLoading ? null : _handleClaimReward,
          isLoading: _isLoading,
        );
      }
    }

    // Logic: If opened from Rewards Wallet
    if (widget.isFromWallet && isClaimed) {
      final rewardType = widget.milestone.reward?.fulfillmentType ?? '';
      final bool isBackendReady =
          rewardType == 'CONTEXTUAL' || rewardType == 'DELIVERY';

      return _buildButtonWrapper(
        text: widget.l10n.useRewardBtn,
        color: isBackendReady
            ? widget.colors.success
            : widget.colors.iconGrey.withValues(alpha: 0.3),
        textColor: isBackendReady
            ? widget.colors.surface
            : widget.colors.iconGrey,
        onPressed: isBackendReady ? _handleUseReward : null,
        icon: Icons.play_arrow_rounded,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildButtonWrapper({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: widget.colors.surface,
          disabledForegroundColor: widget.colors.iconGrey,
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.spacingMedium * 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
          elevation: onPressed != null ? 4 : 0,
        ),
        child: isLoading
            ? SizedBox(
                height: Dimensions.iconMedium,
                width: Dimensions.iconMedium,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: Dimensions.iconMedium, color: textColor),
                    SizedBox(width: Dimensions.spacingSmall),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: Dimensions.fontTitleMedium,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
