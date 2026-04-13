import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/payment_method_model.dart';
import '../providers/payment_methods_provider.dart';
import '../providers/subscription_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final int planId;
  final String planName;
  final double price;
  final int rewardPoints;
  final String gymName;

  const CheckoutScreen({
    super.key,
    required this.planId,
    required this.planName,
    required this.price,
    required this.rewardPoints,
    required this.gymName,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final Logger _logger = Logger('CheckoutScreen');
  bool _isLoading = false;
  String? _selectedGatewayId;

  @override
  void initState() {
    super.initState();
    // Default selection to the first available method after the widget tree builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final methods = ref.read(paymentMethodsProvider);
      if (methods.isNotEmpty && mounted) {
        setState(() => _selectedGatewayId = methods.first.id);
      }
    });
  }

  Future<void> _processPayment(AppLocalizations l10n, AppColors colors) async {
    if (_selectedGatewayId == null) {
      _showSnackBar(context, 'Please select a payment method', colors.error);
      return;
    }

    setState(() => _isLoading = true);

    // ARCHITECTURE NOTE: For testing, the API only accepts 'mock'.
    // We force the value to 'mock' here. When connecting real gateways, remove this override.
    final String apiGatewayValue = 'mock';

    try {
      final apiService = ref.read(subscriptionApiServiceProvider);
      await apiService.checkout(widget.planId, apiGatewayValue);

      ref
          .read(authControllerProvider.notifier)
          .addLoyaltyPoints(widget.rewardPoints);

      if (mounted) {
        _showSnackBar(context, l10n.paymentSuccess, Colors.green);
        ref.invalidate(mySubscriptionsProvider);
        context.go(RoutePaths.mySubscriptions);
      }
    } catch (e) {
      _logger.severe('Payment process failed', e);
      if (mounted) {
        _showSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
          colors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  /// Helper to map the translation key from the model to the actual localized string
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: l10n.localeName,
      symbol: '',
    );
    final List<PaymentMethodModel> paymentMethods = ref.watch(
      paymentMethodsProvider,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.checkoutTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Dimensions.spacingLarge),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderSummary,
                      style: TextStyle(
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),
                    Container(
                      padding: EdgeInsets.all(Dimensions.spacingLarge),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadiusLarge,
                        ),
                        border: Border.all(
                          color: colors.iconGrey.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.planName,
                                      style: TextStyle(
                                        fontSize: Dimensions.fontBodyLarge,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: Dimensions.spacingTiny),
                                    Text(
                                      widget.gymName,
                                      style: TextStyle(
                                        fontSize: Dimensions.fontBodyMedium,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${currencyFormat.format(widget.price)} ${l10n.sar}',
                                style: TextStyle(
                                  fontSize: Dimensions.fontTitleMedium,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.spacingMedium,
                            ),
                            child: Divider(
                              color: colors.iconGrey.withOpacity(0.2),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: const Color(0xFFF57F17),
                                    size: Dimensions.iconMedium,
                                  ),
                                  SizedBox(width: Dimensions.spacingSmall),
                                  Text(
                                    l10n.earnPoints,
                                    style: TextStyle(
                                      fontSize: Dimensions.fontBodyMedium,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '+${widget.rewardPoints}',
                                style: TextStyle(
                                  fontSize: Dimensions.fontBodyLarge,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Dimensions.spacingExtraLarge),

                    Text(
                      l10n.paymentMethod,
                      style: TextStyle(
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    // ARCHITECTURE FIX: Dynamic rendering of payment methods
                    ...paymentMethods.map((method) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: Dimensions.spacingMedium,
                        ),
                        child: _buildPaymentMethodOption(
                          id: method.id,
                          title: _getLocalizedPaymentName(
                            method.translationKey,
                            l10n,
                          ),
                          icon: method.icon,
                          colors: colors,
                          isSelected: _selectedGatewayId == method.id,
                          onTap: () =>
                              setState(() => _selectedGatewayId = method.id),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                          l10n.totalAmount,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currencyFormat.format(widget.price)} ${l10n.sar}',
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
                            shadowColor: colors.primary.withOpacity(0.4),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => _processPayment(l10n, colors),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String id,
    required String title,
    required IconData icon,
    required AppColors colors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.05) : colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.iconGrey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : colors.textPrimary,
              size: Dimensions.iconLarge * 1.2,
            ),
            SizedBox(width: Dimensions.spacingLarge),
            Expanded(
              child: Text(
                title,
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
                  color: isSelected ? colors.primary : colors.iconGrey,
                  width: 2,
                ),
                color: isSelected ? colors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
