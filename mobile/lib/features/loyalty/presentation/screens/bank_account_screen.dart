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

class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final Logger _logger = Logger('BankAccountScreen');

  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ibanController;
  late TextEditingController _beneficiaryNameController;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ibanController = TextEditingController();
    _beneficiaryNameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preFillData();
    });
  }

  void _preFillData() {
    final walletState = ref.read(loyaltyWalletProvider);
    walletState.whenData((wallet) {
      if (wallet.bankAccount != null) {
        _bankNameController.text = wallet.bankAccount!.bankName;
        _accountNumberController.text = wallet.bankAccount!.accountNumber
            .replaceAll('*', '');
        _ibanController.text = wallet.bankAccount!.iban;
        _beneficiaryNameController.text = wallet.bankAccount!.beneficiaryName;
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _beneficiaryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.addBankAccount,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ARCHITECTURE FIX: Unified Premium Alert Banner
                PremiumAlertBanner(
                  colors: colors,
                  themeColor: colors.primary,
                  icon: Icons.account_balance_wallet_rounded,
                  title: l10n.addBankAccount,
                  subtitle: l10n.dashboardDesc,
                ),
                SizedBox(height: Dimensions.spacingExtraLarge),

                // ARCHITECTURE FIX: Premium Card Wrapper
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
                    children: [
                      PremiumTextField(
                        controller: _bankNameController,
                        label: l10n.bankName,
                        icon: Icons.account_balance_rounded,
                        colors: colors,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? l10n.errorValidation
                            : null,
                      ),
                      SizedBox(height: Dimensions.spacingMedium),

                      PremiumTextField(
                        controller: _accountNumberController,
                        label: l10n.accountNumber,
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        colors: colors,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? l10n.errorValidation
                            : null,
                      ),
                      SizedBox(height: Dimensions.spacingMedium),

                      PremiumTextField(
                        controller: _ibanController,
                        label: l10n.iban,
                        icon: Icons.qr_code_rounded,
                        textCapitalization: TextCapitalization.characters,
                        colors: colors,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.errorValidation;
                          }
                          if (value.trim().length < 15)
                            return l10n.enterValidIban;
                          return null;
                        },
                      ),
                      SizedBox(height: Dimensions.spacingMedium),

                      PremiumTextField(
                        controller: _beneficiaryNameController,
                        label: l10n.beneficiaryName,
                        icon: Icons.person_rounded,
                        colors: colors,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.nameRequired;
                          }
                          if (!AppValidators.nameRegex.hasMatch(value.trim())) {
                            return l10n.invalidName;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

                _buildSubmitButton(colors, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppColors colors, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.2,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
          elevation: _isProcessing ? 0 : 4,
          shadowColor: colors.primary.withOpacity(0.4),
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
                l10n.saveAccount,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.read(appThemeProvider);

    try {
      final apiService = ref.read(loyaltyApiServiceProvider);

      final bool success = await apiService.addOrUpdateBankAccount(
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        iban: _ibanController.text.trim().toUpperCase(),
        beneficiaryName: _beneficiaryNameController.text.trim(),
      );

      if (success && mounted) {
        ref.invalidate(loyaltyWalletProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountSavedSuccessfully,
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
      _logger.severe('Failed to save bank account', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorOops,
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
}
