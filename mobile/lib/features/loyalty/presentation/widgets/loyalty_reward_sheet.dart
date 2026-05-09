import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
import '../../../subscriptions/data/models/subscription_model.dart';

class LoyaltyRewardSheet extends ConsumerStatefulWidget {
  final UserMilestone userMilestone;
  final AppColors colors;
  final AppLocalizations l10n;

  const LoyaltyRewardSheet({
    super.key,
    required this.userMilestone,
    required this.colors,
    required this.l10n,
  });

  @override
  ConsumerState<LoyaltyRewardSheet> createState() => _LoyaltyRewardSheetState();
}

class _LoyaltyRewardSheetState extends ConsumerState<LoyaltyRewardSheet> {
  static final Logger _logger = Logger('LoyaltyRewardSheet');
  bool _isLoading = false;
  bool _isCopied = false;
  SubscriptionModel? _selectedSubscription;

  Future<void> _handleExtendSubscription() async {
    if (_selectedSubscription == null) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      await apiService.extendSubscription(
        userMilestoneId: widget.userMilestone.id,
        subscriptionId: _selectedSubscription!.id,
      );

      _logger.info('Subscription extended successfully');

      ref.invalidate(mySubscriptionsProvider);
      ref.invalidate(allUserMilestonesProvider);
      ref.invalidate(dashboardRewardsProvider);
      ref.invalidate(rewardsSummaryProvider);

      if (mounted) {
        // ARCHITECTURE FIX: Return true to signal the parent screen to refresh local data
        Navigator.pop(context, true);
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

  void _handleCopyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isConsumed = widget.userMilestone.isConsumed;
    final milestone = widget.userMilestone.milestone;

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
                width: Dimensions.spacingExtraLarge * 2.5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.colors.iconGrey.withValues(alpha: 0.2),
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
                      fontWeight: FontWeight.w900,
                      color: widget.colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(Dimensions.spacingSmall),
                      decoration: BoxDecoration(
                        color: widget.colors.iconGrey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: Dimensions.iconMedium,
                        color: widget.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.2),

              Text(
                milestone.reward?.name ?? milestone.title,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1 * 1.1,
                  fontWeight: FontWeight.w900,
                  color: widget.colors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              if (!isConsumed && widget.userMilestone.rewardPayload != null)
                _buildDynamicPayloadUI(widget.userMilestone.rewardPayload!)
              else
                _buildGlowingStaticIcon(isConsumed),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              Text(
                milestone.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.w700,
                  color: widget.colors.textPrimary,
                  height: 1.5,
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 2),

              _buildContextualActionButton(isConsumed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingStaticIcon(bool isConsumed) {
    final Color glowColor = isConsumed
        ? widget.colors.iconGrey
        : widget.colors.success;

    return Container(
      padding: EdgeInsets.all(Dimensions.spacingExtraLarge * 1.5),
      decoration: BoxDecoration(
        color: widget.colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: glowColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isConsumed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
          size: Dimensions.iconLarge * 3,
          color: glowColor,
        ),
      ),
    );
  }

  Widget _buildDynamicPayloadUI(RewardPayload payload) {
    switch (payload.fulfillmentType) {
      case 'coupon':
        return _buildPremiumCouponUI(payload);
      case 'roaming_pass':
        return _buildRoamingPassUI(payload.qrCodeSignature ?? '');
      case 'subscription_extension':
        return _buildPremiumHorizontalExtensionUI();
      case 'manual':
      default:
        return _buildManualUI();
    }
  }

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
    final Color ticketColor = _getCouponColor(payload.couponType);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.5),
        boxShadow: [
          BoxShadow(
            color: ticketColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
            decoration: BoxDecoration(
              color: ticketColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Dimensions.borderRadiusLarge * 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.rewardValue,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          color: ticketColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingTiny),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading1 * 1.2,
                            fontWeight: FontWeight.w900,
                            color: ticketColor,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingMedium),
                  decoration: BoxDecoration(
                    color: widget.colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ticketColor.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    iconType,
                    color: ticketColor,
                    size: Dimensions.iconLarge,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            alignment: Alignment.center,
            children: [
              Container(height: 1, color: widget.colors.surface),
              Row(
                children: List.generate(
                  30,
                  (index) => Expanded(
                    child: Container(
                      height: 2,
                      color: index.isEven
                          ? widget.colors.iconGrey.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: widget.colors.background,
                ),
              ),
              Positioned(
                right: -10,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: widget.colors.background,
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
            child: Column(
              children: [
                if (formattedDate.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: Dimensions.iconSmall,
                        color: widget.colors.textSecondary,
                      ),
                      SizedBox(width: Dimensions.spacingTiny),
                      Text(
                        '${widget.l10n.expiresAt} $formattedDate',
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          color: widget.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingLarge),
                ],
                GestureDetector(
                  onTap: () => _handleCopyCode(code),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingLarge,
                      vertical: Dimensions.spacingMedium,
                    ),
                    decoration: BoxDecoration(
                      color: widget.colors.background,
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                      border: Border.all(
                        color: ticketColor.withValues(alpha: 0.3),
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
                            letterSpacing: 2.0,
                            fontSize: Dimensions.fontTitleMedium,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 1.5,
                              height: Dimensions.spacingLarge,
                              color: widget.colors.iconGrey.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            SizedBox(width: Dimensions.spacingMedium),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                              child: _isCopied
                                  ? Row(
                                      key: const ValueKey('copied'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.l10n.copiedSuccessfully,
                                          style: TextStyle(
                                            fontSize: Dimensions.fontBodySmall,
                                            fontWeight: FontWeight.bold,
                                            color: widget.colors.success,
                                          ),
                                        ),
                                        SizedBox(width: Dimensions.spacingTiny),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: Dimensions.iconMedium,
                                          color: widget.colors.success,
                                        ),
                                      ],
                                    )
                                  : Icon(
                                      Icons.copy_rounded,
                                      key: const ValueKey('copy'),
                                      size: Dimensions.iconMedium,
                                      color: ticketColor,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoamingPassUI(String qrData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _showFullScreenQr(qrData),
          child: Container(
            width: Dimensions.screenWidth * 0.55,
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Dimensions.borderRadiusLarge * 1.2,
              ),
              border: Border.all(
                color: widget.colors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                SizedBox(height: Dimensions.spacingLarge),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingTiny,
                  ),
                  decoration: BoxDecoration(
                    color: widget.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                          fontWeight: FontWeight.w800,
                          fontSize: Dimensions.fontBodySmall,
                          color: widget.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Dimensions.spacingLarge),
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

  void _showFullScreenQr(String qrData) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.white,
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

  Widget _buildPremiumHorizontalExtensionUI() {
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
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            decoration: BoxDecoration(
              color: widget.colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
              border: Border.all(
                color: widget.colors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: widget.colors.warning,
                  size: Dimensions.iconLarge,
                ),
                SizedBox(width: Dimensions.spacingMedium),
                Expanded(
                  child: Text(
                    widget.l10n.noActiveSubscriptions,
                    style: TextStyle(
                      color: widget.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
              child: Text(
                widget.l10n.selectSubscription,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: Dimensions.fontBodyMedium,
                  color: widget.colors.textSecondary,
                ),
              ),
            ),
            SizedBox(
              height: Dimensions.iconLarge * 3.8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: activeSubs.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: Dimensions.spacingMedium),
                itemBuilder: (context, index) {
                  final sub = activeSubs[index];
                  final bool isSelected = _selectedSubscription?.id == sub.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSubscription = sub);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: Dimensions.screenWidth * 0.75,
                      padding: EdgeInsets.all(Dimensions.spacingMedium),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.colors.primary.withValues(alpha: 0.05)
                            : widget.colors.surface,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadiusLarge,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? widget.colors.primary
                              : widget.colors.iconGrey.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: widget.colors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: Dimensions.iconLarge * 2.2,
                            height: Dimensions.iconLarge * 2.2,
                            decoration: BoxDecoration(
                              color: widget.colors.background,
                              borderRadius: BorderRadius.circular(
                                Dimensions.borderRadius,
                              ),
                              border: Border.all(
                                color: widget.colors.iconGrey.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                sub.branchLogo != null &&
                                    sub.branchLogo!.isNotEmpty
                                ? Image.network(
                                    sub.branchLogo!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.fitness_center_rounded,
                                          color: widget.colors.iconGrey,
                                        ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: SizedBox(
                                              width: Dimensions.iconMedium,
                                              height: Dimensions.iconMedium,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: widget.colors.primary,
                                              ),
                                            ),
                                          );
                                        },
                                  )
                                : Icon(
                                    Icons.fitness_center_rounded,
                                    color: widget.colors.iconGrey,
                                  ),
                          ),
                          SizedBox(width: Dimensions.spacingMedium),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.planName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: Dimensions.fontBodyLarge,
                                    color: isSelected
                                        ? widget.colors.primary
                                        : widget.colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: Dimensions.spacingTiny),
                                Text(
                                  sub.providerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: Dimensions.fontBodySmall,
                                    color: widget.colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: Dimensions.spacingSmall),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? widget.colors.primary
                                : widget.colors.iconGrey.withValues(alpha: 0.3),
                            size: Dimensions.iconLarge,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManualUI() {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
      decoration: BoxDecoration(
        color: widget.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
      ),
      child: Column(
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
              color: widget.colors.textPrimary,
              fontSize: Dimensions.fontBodyLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualActionButton(bool isConsumed) {
    if (isConsumed) {
      return _buildButtonWrapper(
        text: widget.l10n.consumedBtn,
        color: widget.colors.background,
        textColor: widget.colors.iconGrey,
        borderColor: widget.colors.iconGrey.withValues(alpha: 0.2),
        onPressed: null,
      );
    }

    if (widget.userMilestone.rewardPayload != null) {
      final payloadType = widget.userMilestone.rewardPayload!.fulfillmentType;

      if (payloadType == 'subscription_extension') {
        return _buildButtonWrapper(
          text: widget.l10n.extendSubscriptionBtn,
          color: _selectedSubscription != null
              ? widget.colors.success
              : widget.colors.background,
          textColor: _selectedSubscription != null
              ? widget.colors.surface
              : widget.colors.iconGrey,
          borderColor: _selectedSubscription != null
              ? Colors.transparent
              : widget.colors.iconGrey.withValues(alpha: 0.2),
          onPressed: _selectedSubscription != null && !_isLoading
              ? _handleExtendSubscription
              : null,
          isLoading: _isLoading,
          icon: Icons.update_rounded,
        );
      }

      if (payloadType == 'coupon' ||
          payloadType == 'roaming_pass' ||
          payloadType == 'manual') {
        return const SizedBox.shrink();
      }
    }

    final actionRoute = widget.userMilestone.milestone.reward?.actionRoute;
    return _buildButtonWrapper(
      text: widget.l10n.useRewardBtn,
      color: actionRoute != null
          ? widget.colors.primary
          : widget.colors.background,
      textColor: actionRoute != null
          ? widget.colors.surface
          : widget.colors.iconGrey,
      borderColor: actionRoute != null
          ? Colors.transparent
          : widget.colors.iconGrey.withValues(alpha: 0.2),
      onPressed: actionRoute != null
          ? () {
              Navigator.pop(context);
              context.push(actionRoute);
            }
          : null,
      icon: Icons.arrow_forward_rounded,
    );
  }

  Widget _buildButtonWrapper({
    required String text,
    required Color color,
    required Color textColor,
    Color borderColor = Colors.transparent,
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
          disabledBackgroundColor: widget.colors.background,
          disabledForegroundColor: widget.colors.iconGrey,
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.spacingMedium * 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          elevation: onPressed != null && borderColor == Colors.transparent
              ? 8
              : 0,
          shadowColor: color.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? SizedBox(
                height: Dimensions.iconMedium,
                width: Dimensions.iconMedium,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 3.0,
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getCouponDisplayValue(String? type, double value) {
    if (type == 'free_shipping') return widget.l10n.freeShipping;
    if (type == 'bogo') return widget.l10n.bogoDiscount;
    if (type == 'free_item') return widget.l10n.freeItem;
    if (type == 'percentage') return '${value.toStringAsFixed(0)}%';
    if (type == 'fixed_amount')
      return '${value.toStringAsFixed(0)} ${widget.l10n.currency}';
    return value.toStringAsFixed(0);
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

  Color _getCouponColor(String? type) {
    switch (type) {
      case 'free_shipping':
        return widget.colors.success;
      case 'bogo':
        return widget.colors.primary;
      case 'free_item':
        return widget.colors.warning;
      case 'percentage':
        return widget.colors.warning;
      case 'fixed_amount':
        return widget.colors.primary;
      default:
        return widget.colors.primary;
    }
  }
}
