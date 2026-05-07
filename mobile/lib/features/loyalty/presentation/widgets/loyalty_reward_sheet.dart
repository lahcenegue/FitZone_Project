import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../subscriptions/data/models/subscription_model.dart';

class LoyaltyRewardSheet extends ConsumerStatefulWidget {
  final LoyaltyMilestone milestone;
  final UserMilestoneData? userMilestoneData;
  final UserMilestone? userMilestoneWallet;
  final bool isFromWallet;
  final AppColors colors;
  final AppLocalizations l10n;

  const LoyaltyRewardSheet({
    super.key,
    required this.milestone,
    this.userMilestoneData,
    this.userMilestoneWallet,
    required this.isFromWallet,
    required this.colors,
    required this.l10n,
  });

  @override
  ConsumerState<LoyaltyRewardSheet> createState() => _LoyaltyRewardSheetState();
}

class _LoyaltyRewardSheetState extends ConsumerState<LoyaltyRewardSheet>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('LoyaltyRewardSheet');
  bool _isLoading = false;
  bool _isUnboxing = false;
  SubscriptionModel? _selectedSubscription;

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

      ref.invalidate(allUserMilestonesProvider);
      ref.invalidate(dashboardRewardsProvider);
      ref.invalidate(rewardsSummaryProvider);
      ref.invalidate(loyaltyWalletProvider);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUnboxing = true;
        });

        await Future.delayed(const Duration(milliseconds: 2500));
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
            widget.l10n.rewardClaimedSuccess,
            widget.colors.success,
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to claim reward', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(widget.l10n.errorOops, widget.colors.error);
      }
    }
  }

  Future<void> _handleExtendSubscription() async {
    if (widget.userMilestoneWallet == null || _selectedSubscription == null)
      return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      await apiService.extendSubscription(
        userMilestoneId: widget.userMilestoneWallet!.id,
        subscriptionId: _selectedSubscription!.id,
      );

      _logger.info('Subscription extended successfully');

      ref.invalidate(mySubscriptionsProvider);
      ref.invalidate(allUserMilestonesProvider);
      ref.invalidate(dashboardRewardsProvider);
      ref.invalidate(rewardsSummaryProvider);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(widget.l10n.rewardConsumedSuccess, widget.colors.success);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to extend subscription', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(widget.l10n.errorOops, widget.colors.error);
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
    String status = 'locked';
    if (_isUnboxing) {
      status = 'claimed';
    } else if (widget.isFromWallet && widget.userMilestoneWallet != null) {
      status = widget.userMilestoneWallet!.isConsumed ? 'consumed' : 'claimed';
    } else if (!widget.isFromWallet && widget.userMilestoneData != null) {
      status = widget.userMilestoneData!.status;
    }

    final bool isUnlocked = status != 'locked';
    final bool isClaimed = status == 'claimed' || status == 'consumed';
    final bool isConsumed = status == 'consumed';

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: Dimensions.screenHeight * 0.9),
        decoration: BoxDecoration(
          color: widget.colors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimensions.borderRadiusLarge * 2),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Dimensions.spacingExtraLarge,
            Dimensions.spacingMedium,
            Dimensions.spacingExtraLarge,
            Dimensions.spacingExtraLarge * 2 +
                MediaQuery.of(context).viewInsets.bottom,
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
                _isUnboxing
                    ? widget.l10n.unboxedTitle
                    : (widget.milestone.reward?.name ?? widget.milestone.title),
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1,
                  fontWeight: FontWeight.w900,
                  color: widget.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.spacingSmall),

              if (!_isUnboxing)
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

              // Visual Avatar, Pre-claim details, or Dynamic Payload UI
              if (_isUnboxing)
                _buildUnboxingAnimation()
              else if (widget.isFromWallet &&
                  isClaimed &&
                  !isConsumed &&
                  widget.userMilestoneWallet?.rewardPayload != null)
                _buildDynamicPayloadUI(
                  widget.userMilestoneWallet!.rewardPayload!,
                )
              else
                _buildPreClaimOrStaticIcon(isUnlocked, isConsumed),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              if (!_isUnboxing) ...[
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

                if (!widget.isFromWallet || (widget.isFromWallet && isConsumed))
                  Text(
                    isUnlocked
                        ? (isConsumed
                              ? widget.l10n.consumedDesc
                              : (isClaimed
                                    ? widget.l10n.alreadyClaimedMsg
                                    : widget.l10n.unlockedDesc))
                        : widget.l10n.lockedDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      color: widget.colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
              ],
              SizedBox(height: Dimensions.spacingExtraLarge * 2),

              if (!_isUnboxing) _buildContextualActionButton(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnboxingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(Dimensions.spacingExtraLarge * 1.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.colors.star, widget.colors.warning],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.colors.warning.withValues(alpha: 0.6),
                  blurRadius: 40 * value,
                  spreadRadius: 15 * value,
                ),
              ],
            ),
            child: Icon(
              Icons.redeem_rounded,
              size: Dimensions.iconLarge * 3.5,
              color: widget.colors.surface,
            ),
          ),
        );
      },
    );
  }

  /// Builds the pre-claim details if available, otherwise just a static icon
  Widget _buildPreClaimOrStaticIcon(bool isUnlocked, bool isConsumed) {
    final reward = widget.milestone.reward;

    // ARCHITECTURE FIX: Display reward value proactively if available before claiming
    if (isUnlocked &&
        !isConsumed &&
        reward != null &&
        reward.discountValue != null &&
        reward.discountValue! > 0) {
      return Container(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: widget.colors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.colors.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              _getCouponIcon(reward.couponType),
              size: Dimensions.iconLarge * 2,
              color: widget.colors.primary,
            ),
            SizedBox(height: Dimensions.spacingMedium),
            Text(
              widget.l10n.rewardValue,
              style: TextStyle(
                color: widget.colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Dimensions.spacingTiny),
            Text(
              _getCouponDisplayValue(reward.couponType, reward.discountValue!),
              style: TextStyle(
                fontSize: Dimensions.fontHeading2,
                fontWeight: FontWeight.w900,
                color: widget.colors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimensions.spacingExtraLarge * 1.5),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isConsumed
                  ? widget.colors.iconGrey.withValues(alpha: 0.1)
                  : widget.colors.primary.withValues(alpha: 0.1))
            : widget.colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnlocked
              ? (isConsumed
                    ? widget.colors.iconGrey.withValues(alpha: 0.3)
                    : widget.colors.primary.withValues(alpha: 0.3))
              : widget.colors.iconGrey.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Icon(
        isUnlocked
            ? (isConsumed
                  ? Icons.check_circle_rounded
                  : Icons.card_giftcard_rounded)
            : Icons.lock_rounded,
        size: Dimensions.iconLarge * 3,
        color: isUnlocked
            ? (isConsumed ? widget.colors.iconGrey : widget.colors.primary)
            : widget.colors.iconGrey.withValues(alpha: 0.5),
      ),
    );
  }

  // --- DYNAMIC POLYMORPHIC PAYLOAD UI ---
  Widget _buildDynamicPayloadUI(RewardPayload payload) {
    switch (payload.fulfillmentType) {
      case 'coupon':
        return _buildPremiumCouponUI(payload);
      case 'roaming_pass':
        return _buildRoamingPassUI(payload.qrCodeSignature ?? '');
      case 'subscription_extension':
        return _buildExtensionUI();
      case 'manual':
      default:
        return _buildManualUI();
    }
  }

  /// Premium Minimalist Ticket Design (Out of the box)
  Widget _buildPremiumCouponUI(RewardPayload payload) {
    final String currentLocale = Localizations.localeOf(context).languageCode;
    final String code = payload.couponCode ?? '';
    final String formattedDate = payload.expiresAt != null
        ? DateFormat(
            'MMM dd, yyyy',
            currentLocale,
          ).format(DateTime.parse(payload.expiresAt!).toLocal())
        : '';

    final String displayValue = _getCouponDisplayValue(
      payload.couponType,
      payload.discountValue ?? 0,
    );
    final IconData iconType = _getCouponIcon(payload.couponType);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(
          color: widget.colors.iconGrey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Side: Brand Accent & Icon
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.spacingLarge,
              vertical: Dimensions.spacingExtraLarge,
            ),
            decoration: BoxDecoration(
              color: widget.colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(
                  currentLocale == 'ar' ? 0 : Dimensions.borderRadiusLarge,
                ),
                right: Radius.circular(
                  currentLocale == 'ar' ? Dimensions.borderRadiusLarge : 0,
                ),
              ),
            ),
            child: Icon(
              iconType,
              size: Dimensions.iconLarge * 1.5,
              color: widget.colors.primary,
            ),
          ),

          // Dashed Divider (Clean UI implementation)
          Container(
            height: 100,
            width: 2,
            child: Flex(
              direction: Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                12,
                (_) => SizedBox(
                  width: 2,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.colors.iconGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Side: Content & Action
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: Dimensions.fontTitleLarge,
                      fontWeight: FontWeight.w900,
                      color: widget.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  if (formattedDate.isNotEmpty)
                    Text(
                      '${widget.l10n.expiresAt} $formattedDate',
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        color: widget.colors.textSecondary,
                      ),
                    ),
                  SizedBox(height: Dimensions.spacingMedium),

                  // Copy Code Button Area
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      _showSnackBar(
                        widget.l10n.copiedSuccessfully,
                        widget.colors.success,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spacingMedium,
                        vertical: Dimensions.spacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: widget.colors.background,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadius,
                        ),
                        border: Border.all(
                          color: widget.colors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            code,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: widget.colors.textPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Icon(
                            Icons.copy_rounded,
                            size: Dimensions.iconSmall,
                            color: widget.colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a clickable QR code that expands to full screen
  Widget _buildRoamingPassUI(String qrData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () =>
              _showFullScreenQr(qrData), // Interactive Fullscreen Trigger
          child: Container(
            width: Dimensions.screenWidth * 0.5,
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
              border: Border.all(
                color: widget.colors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.primary.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                PrettyQrView.data(
                  data: qrData,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(color: Colors.black87),
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fullscreen_rounded,
                      size: Dimensions.iconSmall,
                      color: widget.colors.primary,
                    ),
                    SizedBox(width: Dimensions.spacingTiny),
                    Text(
                      widget.l10n.tapToExpandQr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.fontBodySmall,
                        color: widget.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Dimensions.spacingMedium),
        Text(
          widget.l10n.showToReception,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: widget.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Full Screen QR Dialog for easy scanning by reception
  void _showFullScreenQr(String qrData) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.white, // Pure white for scanner visibility
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.black87,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.spacingExtraLarge * 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrettyQrView.data(
                      data: qrData,
                      errorCorrectLevel: QrErrorCorrectLevel.H,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: Colors.black87),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge * 2),
                    Text(
                      widget.l10n.showToReception,
                      style: TextStyle(
                        fontSize: Dimensions.fontTitleLarge,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtensionUI() {
    final subscriptionsAsync = ref.watch(mySubscriptionsProvider);

    return subscriptionsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: widget.colors.primary),
      ),
      error: (e, s) => Text(
        widget.l10n.errorLoadingDetails,
        style: TextStyle(color: widget.colors.error),
      ),
      data: (subscriptions) {
        final activeSubs = subscriptions
            .where((sub) => sub.status == 'active')
            .toList();

        if (activeSubs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            decoration: BoxDecoration(
              color: widget.colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: widget.colors.warning),
                SizedBox(width: Dimensions.spacingSmall),
                Expanded(
                  child: Text(
                    widget.l10n.noActiveSubscriptions,
                    style: TextStyle(
                      color: widget.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          decoration: BoxDecoration(
            color: widget.colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(
              color: widget.colors.iconGrey.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SubscriptionModel>(
              value: _selectedSubscription,
              isExpanded: true,
              hint: Text(
                widget.l10n.selectSubscription,
                style: TextStyle(
                  color: widget.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: widget.colors.primary,
              ),
              items: activeSubs.map((sub) {
                return DropdownMenuItem(
                  value: sub,
                  child: Text(
                    '${sub.planName} - ${sub.providerName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.colors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedSubscription = val);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualUI() {
    return Column(
      children: [
        Icon(
          Icons.front_hand_rounded,
          size: Dimensions.iconLarge * 2,
          color: widget.colors.primary,
        ),
        SizedBox(height: Dimensions.spacingMedium),
        Text(
          widget.l10n.rewardManualDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.colors.textSecondary,
            fontSize: Dimensions.fontBodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildContextualActionButton(String status) {
    if (status == 'locked') {
      return _buildButtonWrapper(
        text: widget.l10n.lockedBtn,
        color: widget.colors.surface,
        textColor: widget.colors.iconGrey,
        onPressed: null,
      );
    }

    if (status == 'consumed') {
      return _buildButtonWrapper(
        text: widget.l10n.consumedBtn,
        color: widget.colors.iconGrey.withValues(alpha: 0.1),
        textColor: widget.colors.iconGrey,
        onPressed: null,
      );
    }

    // STRICT SEPARATION: If opened from Gamified Track
    if (!widget.isFromWallet) {
      if (status == 'claimed') {
        return _buildButtonWrapper(
          text: widget.l10n.goToWalletBtn,
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

    // STRICT SEPARATION: If opened from Rewards Wallet
    if (widget.isFromWallet &&
        status == 'claimed' &&
        widget.userMilestoneWallet?.rewardPayload != null) {
      final payloadType =
          widget.userMilestoneWallet!.rewardPayload!.fulfillmentType;

      if (payloadType == 'subscription_extension') {
        return _buildButtonWrapper(
          text: widget.l10n.extendSubscriptionBtn,
          color: _selectedSubscription != null
              ? widget.colors.success
              : widget.colors.iconGrey.withValues(alpha: 0.3),
          textColor: _selectedSubscription != null
              ? widget.colors.surface
              : widget.colors.iconGrey,
          onPressed: _selectedSubscription != null && !_isLoading
              ? _handleExtendSubscription
              : null,
          isLoading: _isLoading,
          icon: Icons.update_rounded,
        );
      }

      // Hide the main button if the UI already handles the action (e.g., QR full screen or Copy code)
      if (payloadType == 'coupon' ||
          payloadType == 'roaming_pass' ||
          payloadType == 'manual') {
        return const SizedBox.shrink();
      }

      final actionRoute = widget.milestone.reward?.actionRoute;
      return _buildButtonWrapper(
        text: widget.l10n.goToWalletBtn,
        color: actionRoute != null
            ? widget.colors.primary
            : widget.colors.iconGrey.withValues(alpha: 0.3),
        textColor: actionRoute != null
            ? widget.colors.surface
            : widget.colors.iconGrey,
        onPressed: actionRoute != null
            ? () {
                Navigator.pop(context);
                context.push(actionRoute);
              }
            : null,
        icon: Icons.arrow_forward_rounded,
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

  // --- Helper Methods for Translating Coupon Types to UI Elements ---

  String _getCouponDisplayValue(String? type, double value) {
    if (type == 'free_shipping') return widget.l10n.freeShipping;
    if (type == 'bogo') return widget.l10n.bogoDiscount;
    if (type == 'free_item') return widget.l10n.freeItem;
    if (type == 'percentage') return '${value.toStringAsFixed(0)}% OFF';
    if (type == 'fixed_amount') return '\$${value.toStringAsFixed(2)} OFF';
    return '${value.toStringAsFixed(0)}';
  }

  IconData _getCouponIcon(String? type) {
    switch (type) {
      case 'free_shipping':
        return Icons.local_shipping_rounded;
      case 'bogo':
        return Icons.join_inner_rounded;
      case 'free_item':
        return Icons.card_giftcard_rounded;
      case 'percentage':
        return Icons.percent_rounded;
      case 'fixed_amount':
        return Icons.attach_money_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }
}
