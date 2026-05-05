import 'package:fitzone/core/config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/premium_alert_banner.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/loyalty_dashboard_providers.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger('WithdrawScreen');
  late TextEditingController _amountController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(
    double maxAmount,
    AppLocalizations l10n,
    AppColors colors,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text.trim());

    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(loyaltyApiServiceProvider);

      final bool success = await apiService.requestWithdrawal(amount: amount);

      if (success && mounted) {
        _logger.info('Withdrawal successful. Invalidating providers.');

        ref.invalidate(loyaltyWalletProvider);
        ref.invalidate(dashboardTransactionsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.withdrawalRequested,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.pop();
      }
    } catch (e, stackTrace) {
      _logger.severe('Withdrawal request failed', e, stackTrace);
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final walletState = ref.watch(loyaltyWalletProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.withdrawFunds,
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
      body: walletState.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (e, _) => Center(
          child: Text(l10n.errorOops, style: TextStyle(color: colors.error)),
        ),
        data: (wallet) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumAlertBanner(
                      colors: colors,
                      themeColor: colors.primary,
                      icon: Icons.payments_rounded,
                      title:
                          '${l10n.fiatBalance}: ${wallet.fiatBalance.toStringAsFixed(2)} ${l10n.sar}',
                      subtitle: l10n.dashboardDesc,
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge),

                    Container(
                      padding: EdgeInsets.all(Dimensions.spacingLarge),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadiusLarge,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumTextField(
                            label: l10n.withdrawAmount,
                            hintText: '0.00',
                            controller: _amountController,
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            colors: colors,
                            validator: (value) =>
                                AppValidators.validateWithdrawalAmount(
                                  value,
                                  wallet.fiatBalance,
                                  AppConstants.minimumWithdrawalAmount,
                                  l10n,
                                ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

                    SizedBox(
                      width: double.infinity,
                      height: Dimensions.buttonHeight * 1.2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: _isProcessing ? 0 : 4,
                          shadowColor: colors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.borderRadiusLarge,
                            ),
                          ),
                        ),
                        onPressed: _isProcessing
                            ? null
                            : () => _submitRequest(
                                wallet.fiatBalance,
                                l10n,
                                colors,
                              ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3.0,
                                ),
                              )
                            : Text(
                                l10n.confirmWithdrawal,
                                style: TextStyle(
                                  fontSize: Dimensions.fontTitleMedium,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
