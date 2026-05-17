import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/checkout_models.dart';
import '../../data/models/payment_method_model.dart';
import '../providers/checkout_provider.dart';
import '../providers/payment_methods_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String itemType;
  final int itemId;

  const CheckoutScreen({
    super.key,
    required this.itemType,
    required this.itemId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final Logger _logger = Logger('CheckoutScreen');
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  late ValueNotifier<String?> _selectedGatewayNotifier;

  @override
  void initState() {
    super.initState();
    _selectedGatewayNotifier = ValueNotifier<String?>(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final methods = ref.read(paymentMethodsProvider);
      if (methods.isNotEmpty && mounted) {
        _selectedGatewayNotifier.value = methods.first.id;
      }
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    _pointsController.dispose();
    _selectedGatewayNotifier.dispose();
    super.dispose();
  }

  Future<void> _processPayment(
    AppLocalizations l10n,
    AppColors colors,
    double remainingTotal,
  ) async {
    if (remainingTotal > 0 && _selectedGatewayNotifier.value == null) {
      _showSnackBar(context, l10n.selectPaymentMethod, colors.error);
      return;
    }

    try {
      final String? finalGateway = remainingTotal > 0
          ? _selectedGatewayNotifier.value
          : null;
      final controller = ref.read(
        checkoutControllerProvider(widget.itemType, widget.itemId).notifier,
      );

      await controller.processPayment(finalGateway);

      if (mounted) {
        _showSnackBar(context, l10n.paymentSuccess, colors.success);
        context.go(RoutePaths.home);
      }
    } catch (e) {
      _logger.severe('Payment process failed', e);
      if (mounted) {
        _showSnackBar(context, _formatError(e, l10n), colors.error);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color bgColor) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        ),
      ),
    );
  }

  String _formatError(Object? error, AppLocalizations l10n) {
    if (error == null) return '';
    if (error is DioException) {
      return ApiException.fromDioException(error, l10n).message;
    }
    return error.toString();
  }

  String _getLocalizedPaymentName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'applePay':
        return l10n.applePay;
      case 'creditCard':
        return l10n.creditCard;
      default:
        return key;
    }
  }

  String _getLocalizedUnit(String unit, AppLocalizations l10n) {
    switch (unit.toLowerCase()) {
      case 'days':
        return l10n.unitDays;
      case 'points':
        return l10n.unitPoints;
      case 'visit':
        return l10n.unitVisit;
      case 'item':
        return l10n.unitItem;
      default:
        return unit;
    }
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: l10n.localeName,
      symbol: '',
    );

    final checkoutState = ref.watch(
      checkoutControllerProvider(widget.itemType, widget.itemId),
    );
    final controllerNotifier = ref.read(
      checkoutControllerProvider(widget.itemType, widget.itemId).notifier,
    );
    final paymentMethods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.checkoutTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(
          checkoutState,
          colors,
          l10n,
          currencyFormat,
          controllerNotifier,
          paymentMethods,
        ),
      ),
    );
  }

  Widget _buildBody(
    CheckoutState checkoutState,
    AppColors colors,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
    CheckoutController controllerNotifier,
    List<PaymentMethodModel> paymentMethods,
  ) {
    if (checkoutState.isInitialLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (checkoutState.generalError != null &&
        checkoutState.invoiceData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colors.error,
              size: Dimensions.iconLarge,
            ),
            SizedBox(height: Dimensions.spacingMedium),
            Text(
              _formatError(checkoutState.generalError, l10n),
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.spacingMedium),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                controllerNotifier.toggleWallet(true);
              },
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    final previewData = checkoutState.invoiceData!;
    final invoice = previewData.invoice;
    final balances = previewData.userBalances;
    final details = previewData.itemDetails;
    final bool needsGateway = invoice.remainingTotalToPay > 0;

    // ARCHITECTURE FIX: Business logic condition to hide discounts for point packages
    final bool isPointsPackage = widget.itemType == 'points_package';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.orderDetails, colors),
                _buildItemDetailsCard(details, colors, currencyFormat, l10n),
                SizedBox(height: Dimensions.spacingExtraLarge),

                // ARCHITECTURE FIX: Conditionally render the discounts section
                if (!isPointsPackage) ...[
                  _buildSectionTitle(l10n.discount, colors),
                  _buildDiscountsCard(
                    colors,
                    l10n,
                    balances,
                    invoice,
                    checkoutState,
                    controllerNotifier,
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge),
                ],

                _buildSectionTitle(l10n.paymentMethod, colors),
                _buildWalletCard(
                  colors,
                  l10n,
                  balances,
                  checkoutState,
                  controllerNotifier,
                  currencyFormat,
                ),
                SizedBox(height: Dimensions.spacingLarge),

                if (!needsGateway)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Dimensions.spacingMedium),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusLarge,
                      ),
                    ),
                    child: Text(
                      l10n.walletCoversTotal,
                      style: TextStyle(
                        color: colors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.fontBodyMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectPaymentMethod,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodyMedium,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingMedium),
                      _buildPaymentGatewaysList(paymentMethods, colors, l10n),
                    ],
                  ),

                SizedBox(height: Dimensions.spacingExtraLarge),
                _buildSectionTitle(l10n.invoiceSummary, colors),
                _buildInvoiceCard(
                  invoice,
                  colors,
                  l10n,
                  currencyFormat,
                  checkoutState.isUpdatingInvoice,
                ),
                SizedBox(height: Dimensions.spacingExtraLarge * 2),
              ],
            ),
          ),
        ),

        _buildStickyBottomBar(
          colors: colors,
          l10n: l10n,
          currencyFormat: currencyFormat,
          invoice: invoice,
          isProcessing:
              checkoutState.isProcessingPayment ||
              checkoutState.isUpdatingInvoice ||
              checkoutState.isApplyingCoupon,
          onPay: () =>
              _processPayment(l10n, colors, invoice.remainingTotalToPay),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Dimensions.spacingMedium,
        right: Dimensions.spacingSmall,
        left: Dimensions.spacingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontTitleMedium,
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildItemDetailsCard(
    CheckoutItemDetails details,
    AppColors colors,
    NumberFormat fmt,
    AppLocalizations l10n,
  ) {
    final String fullImageUrl = _resolveImageUrl(details.imageUrl);
    final String localizedUnit = _getLocalizedUnit(details.unit, l10n);

    return Container(
      padding: EdgeInsets.all(Dimensions.spacingMedium),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: fullImageUrl.isEmpty
                ? EdgeInsets.all(Dimensions.spacingSmall)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              child: fullImageUrl.isNotEmpty
                  ? Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackImage(colors),
                    )
                  : _buildFallbackImage(colors),
            ),
          ),
          SizedBox(width: Dimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Dimensions.spacingTiny),
                Text(
                  '${l10n.provider} ${details.providerName}',
                  style: TextStyle(
                    fontSize: Dimensions.fontBodySmall,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingTiny,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  child: Text(
                    '${details.quantity} $localizedUnit',
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Dimensions.spacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(details.price),
                style: TextStyle(
                  fontSize: Dimensions.fontTitleLarge,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              if (details.originalPrice != null &&
                  details.originalPrice! > details.price)
                Text(
                  fmt.format(details.originalPrice),
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    color: colors.iconGrey,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                l10n.sar,
                style: TextStyle(
                  fontSize: Dimensions.fontBodySmall,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(AppColors colors) {
    return Image.asset(
      'assets/images/logo.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.stars_rounded,
        color: colors.primary.withValues(alpha: 0.5),
        size: Dimensions.iconLarge,
      ),
    );
  }

  Widget _buildDiscountRow({
    required AppColors colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hintText,
    required bool isEnabled,
    required bool isLoading,
    required String buttonText,
    Color? buttonTextColor,
    required VoidCallback onButtonPressed,
    required TextInputType keyboardType,
    Function(String)? onChanged,
    String? errorMessage,
  }) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.spacingSmall),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: Dimensions.iconMedium,
                ),
              ),
              SizedBox(width: Dimensions.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontSize: Dimensions.fontBodyMedium,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: Dimensions.fontBodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  enabled: isEnabled,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    fontSize: Dimensions.fontBodyMedium,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: colors.iconGrey),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingSmall,
                      vertical: Dimensions.spacingSmall,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      borderSide: BorderSide(
                        color: colors.iconGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      borderSide: BorderSide(
                        color: colors.iconGrey.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                    suffixIcon: isEnabled
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: colors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: onButtonPressed,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      buttonText,
                                      style: TextStyle(
                                        color:
                                            buttonTextColor ?? colors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: Dimensions.fontBodySmall,
                                      ),
                                    ),
                                  ),
                          )
                        : null,
                  ),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          if (errorMessage != null && errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: Dimensions.spacingSmall,
                left: Dimensions.iconMedium + Dimensions.spacingLarge * 2,
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: colors.error,
                  fontSize: Dimensions.fontBodySmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountsCard(
    AppColors colors,
    AppLocalizations l10n,
    CheckoutUserBalances balances,
    CheckoutInvoice invoice,
    CheckoutState checkoutState,
    CheckoutController notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildDiscountRow(
            colors: colors,
            icon: Icons.stars_rounded,
            iconColor: colors.warning,
            title: l10n.redeemPoints,
            subtitle: '${l10n.rewardPoints}: ${balances.totalRewardPoints}',
            controller: _pointsController,
            hintText: '0',
            isEnabled: balances.totalRewardPoints > 0,
            isLoading: false,
            buttonText: l10n.maxBtn,
            keyboardType: TextInputType.number,
            onButtonPressed: () {
              final int maxToApply = min(
                balances.totalRewardPoints,
                invoice.maxPointsAllowed,
              );
              if (maxToApply > 0) {
                _pointsController.text = maxToApply.toString();
                notifier.updatePoints(maxToApply);
              }
            },
            onChanged: (val) => notifier.updatePoints(int.tryParse(val) ?? 0),
          ),
          Divider(height: 1, color: colors.iconGrey.withValues(alpha: 0.1)),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _couponController,
            builder: (context, couponValue, child) {
              final String currentText = couponValue.text.trim();
              final String appliedCode = checkoutState.request.couponCode;
              final bool hasActiveCoupon =
                  appliedCode.isNotEmpty &&
                  checkoutState.couponError == null &&
                  currentText == appliedCode;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiscountRow(
                    colors: colors,
                    icon: Icons.discount_rounded,
                    iconColor: colors.primary,
                    title: l10n.couponCode,
                    subtitle: l10n.enterCouponSubtitle,
                    controller: _couponController,
                    hintText: l10n.couponHint,
                    isEnabled: true,
                    isLoading: checkoutState.isApplyingCoupon,
                    buttonText: hasActiveCoupon ? l10n.removeBtn : l10n.apply,
                    buttonTextColor: hasActiveCoupon
                        ? colors.error
                        : colors.primary,
                    keyboardType: TextInputType.text,
                    errorMessage: _formatError(checkoutState.couponError, l10n),
                    onButtonPressed: () {
                      FocusScope.of(context).unfocus();
                      if (hasActiveCoupon) {
                        _couponController.clear();
                        notifier.applyCoupon('');
                      } else if (currentText.isNotEmpty) {
                        notifier.applyCoupon(currentText);
                      }
                    },
                  ),
                  if (hasActiveCoupon && invoice.discountAmount > 0)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: Dimensions.spacingMedium,
                        left:
                            Dimensions.iconMedium + Dimensions.spacingLarge * 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.success,
                            size: 16,
                          ),
                          SizedBox(width: Dimensions.spacingTiny),
                          Text(
                            l10n.couponAppliedSuccess,
                            style: TextStyle(
                              color: colors.success,
                              fontSize: Dimensions.fontBodySmall,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    AppColors colors,
    AppLocalizations l10n,
    CheckoutUserBalances balances,
    CheckoutState checkoutState,
    CheckoutController notifier,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        activeColor: colors.primary,
        secondary: Container(
          padding: EdgeInsets.all(Dimensions.spacingSmall),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: colors.primary,
            size: Dimensions.iconMedium,
          ),
        ),
        title: Text(
          l10n.useWallet,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Dimensions.fontBodyMedium,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${currencyFormat.format(balances.totalWalletBalance)} ${l10n.sar}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodySmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: checkoutState.request.useWallet,
        onChanged: balances.totalWalletBalance > 0
            ? (val) => notifier.toggleWallet(val)
            : null,
      ),
    );
  }

  Widget _buildPaymentGatewaysList(
    List<PaymentMethodModel> methods,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedGatewayNotifier,
      builder: (context, selectedId, child) {
        return Column(
          children: methods.map((method) {
            final isSelected = selectedId == method.id;
            return Padding(
              padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
              child: InkWell(
                onTap: () => _selectedGatewayNotifier.value = method.id,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(Dimensions.spacingLarge),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.05)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.iconGrey.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method.icon,
                        color: isSelected ? colors.primary : colors.iconGrey,
                        size: Dimensions.iconLarge * 1.2,
                      ),
                      SizedBox(width: Dimensions.spacingLarge),
                      Expanded(
                        child: Text(
                          _getLocalizedPaymentName(method.translationKey, l10n),
                          style: TextStyle(
                            fontSize: Dimensions.fontBodyLarge,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.iconGrey,
                            width: 2,
                          ),
                          color: isSelected
                              ? colors.primary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInvoiceCard(
    CheckoutInvoice invoice,
    AppColors colors,
    AppLocalizations l10n,
    NumberFormat fmt,
    bool isUpdating,
  ) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(color: colors.iconGrey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildInvoiceRow(
                l10n.subtotal,
                fmt.format(invoice.subtotal),
                colors.textPrimary,
                false,
              ),
              SizedBox(height: Dimensions.spacingSmall),
              if (invoice.taxAmount > 0) ...[
                _buildInvoiceRow(
                  l10n.tax,
                  fmt.format(invoice.taxAmount),
                  colors.textPrimary,
                  false,
                ),
                SizedBox(height: Dimensions.spacingSmall),
              ],
              if (invoice.discountAmount > 0) ...[
                _buildInvoiceRow(
                  l10n.discount,
                  '-${fmt.format(invoice.discountAmount)}',
                  colors.success,
                  true,
                ),
                SizedBox(height: Dimensions.spacingSmall),
              ],
              if (invoice.pointsValueApplied > 0) ...[
                _buildInvoiceRow(
                  l10n.pointsDeduction,
                  '-${fmt.format(invoice.pointsValueApplied)}',
                  colors.success,
                  true,
                ),
                SizedBox(height: Dimensions.spacingSmall),
              ],
              if (invoice.walletBalanceApplied > 0) ...[
                _buildInvoiceRow(
                  l10n.walletDeduction,
                  '-${fmt.format(invoice.walletBalanceApplied)}',
                  colors.success,
                  true,
                ),
                SizedBox(height: Dimensions.spacingSmall),
              ],
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.spacingMedium,
                ),
                child: Divider(color: colors.iconGrey.withValues(alpha: 0.3)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalToPay,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyLarge,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        fmt.format(invoice.remainingTotalToPay),
                        style: TextStyle(
                          fontSize: Dimensions.fontHeading2,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingTiny),
                      Text(
                        invoice.currency,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (invoice.expectedRewardPoints > 0) ...[
                SizedBox(height: Dimensions.spacingMedium),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingTiny,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: colors.warning,
                        size: Dimensions.iconSmall,
                      ),
                      SizedBox(width: Dimensions.spacingTiny),
                      Text(
                        '${l10n.expectedRewards}: +${invoice.expectedRewardPoints} ${l10n.pts}',
                        style: TextStyle(
                          color: colors.warning,
                          fontWeight: FontWeight.w800,
                          fontSize: Dimensions.fontBodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceRow(
    String title,
    String value,
    Color color,
    bool isDeduction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDeduction ? color : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar({
    required AppColors colors,
    required AppLocalizations l10n,
    required NumberFormat currencyFormat,
    required CheckoutInvoice invoice,
    required bool isProcessing,
    required VoidCallback onPay,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.totalToPay,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: Dimensions.fontBodySmall,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${currencyFormat.format(invoice.remainingTotalToPay)} ${invoice.currency}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: Dimensions.fontTitleMedium,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(width: Dimensions.spacingLarge),
            Expanded(
              child: SizedBox(
                height: Dimensions.buttonHeight * 1.1,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusLarge,
                      ),
                    ),
                    elevation: 4,
                  ),
                  onPressed: isProcessing ? null : onPay,
                  child: isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: Dimensions.spacingMedium),
                            Text(
                              l10n.processing,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          l10n.payNow,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
