import 'package:fitzone/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/database/local_data_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/register_form_provider.dart';
import '../../../maps/presentation/screens/map_picker_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final Logger _logger = Logger('RegisterScreen');
  final TextEditingController _addressController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final formState = ref.watch(registerFormProvider);
    final authState = ref.watch(authControllerProvider);
    final staticDataAsync = ref.watch(filterStaticDataProvider);

    ref.listen<RegisterFormState>(registerFormProvider, (previous, next) {
      if (previous?.address != next.address &&
          _addressController.text != next.address) {
        _addressController.text = next.address;
      }
    });

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && previous?.value == null) {
            _logger.info('Registration successful, navigating to OTP.');
            context.go('${RoutePaths.verifyOtp}?email=${user.email}');
          }
        },
        error: (error, stackTrace) {
          _logger.warning('Registration failed: $error');
          _showSnackBar(context, error.toString(), colors.error);
        },
      );
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.spacingMedium),
              _buildHeader(l10n, colors),
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
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomTextField(
                      label: 'Full Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline_rounded,
                      errorText: formState.fullNameError,
                      colors: colors,
                      onChanged: (val) => ref
                          .read(registerFormProvider.notifier)
                          .updateFullName(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildCustomTextField(
                      label: l10n.emailAddress,
                      hint: 'user@fitzone.sa',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: formState.emailError,
                      colors: colors,
                      onChanged: (val) => ref
                          .read(registerFormProvider.notifier)
                          .updateEmail(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildCustomTextField(
                      label: l10n.phoneNumber,
                      hint: l10n.phoneNumberHint,
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      errorText: formState.phoneError,
                      colors: colors,
                      onChanged: (val) => ref
                          .read(registerFormProvider.notifier)
                          .updatePhone(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildPasswordField(l10n, formState, colors),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildSectionLabel(l10n.gender, colors),
                    SizedBox(height: Dimensions.spacingSmall),
                    _buildGenderSelector(l10n, formState, colors),
                    if (formState.genderError != null)
                      _buildErrorText(formState.genderError!, colors),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildSectionLabel(l10n.cityOrRegion, colors),
                    SizedBox(height: Dimensions.spacingSmall),
                    _buildCityDropdown(
                      l10n,
                      formState,
                      staticDataAsync,
                      colors,
                    ),
                    if (formState.cityError != null)
                      _buildErrorText(formState.cityError!, colors),
                    SizedBox(height: Dimensions.spacingMedium),

                    _buildAddressField(l10n, formState, colors),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),
              _buildSubmitButton(l10n, formState, authState, colors),
              SizedBox(height: Dimensions.spacingExtraLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.createAccount,
          style: TextStyle(
            fontSize: Dimensions.fontHeading1 * 1.2,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: Dimensions.spacingTiny),
        Text(
          'Join FitZone and start your fitness journey today.',
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    required AppColors colors,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, colors),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          keyboardType: keyboardType,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: _getPremiumInputDecoration(hint, icon, colors, errorText),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    AppLocalizations l10n,
    RegisterFormState formState,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.password, colors),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          obscureText: _isPasswordObscured,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration:
              _getPremiumInputDecoration(
                '••••••••',
                Icons.lock_outline_rounded,
                colors,
                formState.passwordError,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.iconGrey,
                  ),
                  onPressed: () => setState(
                    () => _isPasswordObscured = !_isPasswordObscured,
                  ),
                ),
              ),
          onChanged: (val) =>
              ref.read(registerFormProvider.notifier).updatePassword(val, l10n),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(
    AppLocalizations l10n,
    RegisterFormState formState,
    AppColors colors,
  ) {
    return Row(
      children: [
        _buildGenderOption(
          l10n.male,
          'male',
          Icons.male_rounded,
          formState,
          colors,
          l10n,
        ),
        SizedBox(width: Dimensions.spacingMedium),
        _buildGenderOption(
          l10n.female,
          'female',
          Icons.female_rounded,
          formState,
          colors,
          l10n,
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    String label,
    String value,
    IconData icon,
    RegisterFormState formState,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    final bool isSelected = formState.gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(registerFormProvider.notifier).updateGender(value, l10n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: Dimensions.spacingMedium),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withOpacity(0.1)
                : colors.background,
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.iconGrey.withOpacity(0.2),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.iconGrey,
                size: Dimensions.iconMedium,
              ),
              SizedBox(width: Dimensions.spacingSmall),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown(
    AppLocalizations l10n,
    RegisterFormState formState,
    AsyncValue<dynamic> staticDataAsync,
    AppColors colors,
  ) {
    return staticDataAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) =>
          Text('Failed to load cities', style: TextStyle(color: colors.error)),
      data: (data) {
        return DropdownButtonFormField<String>(
          value: formState.city,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.iconGrey),
          decoration: _getPremiumInputDecoration(
            l10n.selectRegion,
            Icons.location_city_rounded,
            colors,
            null,
          ),
          items: data.cities.map<DropdownMenuItem<String>>((city) {
            return DropdownMenuItem<String>(
              value: city['id'].toString(),
              child: Text(
                city['name'].toString(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) =>
              ref.read(registerFormProvider.notifier).updateCity(val, l10n),
        );
      },
    );
  }

  Widget _buildAddressField(
    AppLocalizations l10n,
    RegisterFormState formState,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(l10n.addressOptional, colors),
        SizedBox(height: Dimensions.spacingSmall),
        GestureDetector(
          onTap: () async {
            final dynamic result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPickerScreen()),
            );

            if (result != null && result is Map<String, dynamic>) {
              _addressController.text = result['address'];
              ref
                  .read(registerFormProvider.notifier)
                  .updateAddress(
                    result['address'],
                    result['lat'],
                    result['lng'],
                  );
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _addressController,
              readOnly: true,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: formState.isFetchingLocation
                    ? l10n.fetchingAddress
                    : l10n.addressHint,
                hintStyle: TextStyle(
                  color: colors.iconGrey,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: colors.iconGrey,
                ),
                suffixIcon: formState.isFetchingLocation
                    ? Padding(
                        padding: EdgeInsets.all(Dimensions.spacingMedium),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.all(Dimensions.spacingTiny),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadius,
                          ),
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: colors.primary,
                        ),
                      ),
                filled: true,
                fillColor: colors.background,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingLarge,
                  vertical: Dimensions.spacingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    AppLocalizations l10n,
    RegisterFormState formState,
    AsyncValue<dynamic> authState,
    AppColors colors,
  ) {
    final bool isLoading = authState.isLoading;
    final bool isEnabled = formState.isValid && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? colors.primary
              : colors.iconGrey.withOpacity(0.3),
          foregroundColor: Colors.white,
          elevation: isEnabled ? 4 : 0,
          shadowColor: colors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
        ),
        onPressed: isEnabled
            ? () {
                if (ref.read(registerFormProvider.notifier).validateAll(l10n)) {
                  // Ensure address is selected
                  if (formState.address.isEmpty || formState.lat == null) {
                    _showSnackBar(
                      context,
                      'Please select your location',
                      colors.error,
                    );
                    return;
                  }

                  final request = ref
                      .read(registerFormProvider.notifier)
                      .toRequestModel();
                  ref
                      .read(authControllerProvider.notifier)
                      .registerUser(request);
                }
              }
            : null,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                l10n.register,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, AppColors colors) {
    return Text(
      text,
      style: TextStyle(
        fontSize: Dimensions.fontBodyMedium,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildErrorText(String error, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(
        top: Dimensions.spacingTiny,
        left: Dimensions.spacingSmall,
      ),
      child: Text(
        error,
        style: TextStyle(
          color: colors.error,
          fontSize: Dimensions.fontBodySmall,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _getPremiumInputDecoration(
    String hint,
    IconData icon,
    AppColors colors,
    String? errorText,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.iconGrey, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, color: colors.iconGrey),
      filled: true,
      fillColor: colors.background, // Match PersonalInfoScreen styling
      errorText: errorText,
      errorMaxLines: 2,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        ),
        margin: EdgeInsets.all(Dimensions.spacingMedium),
      ),
    );
  }
}
