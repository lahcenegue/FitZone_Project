import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_data_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../maps/presentation/screens/map_picker_screen.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedCity;
  double? _selectedLat;
  double? _selectedLng;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final UserModel? user = ref.read(authControllerProvider).value;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');

    _selectedCity = user?.city;
    _selectedLat = user?.lat;
    _selectedLng = user?.lng;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker(AppColors colors) async {
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _addressController.text = result['address'];
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
      });
    }
  }

  Future<void> _saveChanges(AppLocalizations l10n, AppColors colors) async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar(context, l10n.nameRequired, colors.error);
      return;
    }

    final String phone = _phoneController.text.trim();
    // ARCHITECTURE FIX: Enforce uniform validation rules across the app
    if (phone.isNotEmpty && !AppValidators.phoneRegex.hasMatch(phone)) {
      _showSnackBar(context, l10n.invalidPhoneNumber, colors.error);
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> updateData = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': phone,
      'address': _addressController.text.trim(),
      if (_selectedCity != null) 'city': _selectedCity,
      if (_selectedLat != null) 'lat': _selectedLat,
      if (_selectedLng != null) 'lng': _selectedLng,
    };

    final bool success = await ref
        .read(authControllerProvider.notifier)
        .updateProfileData(updateData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _isEditing = false);
        _showSnackBar(context, l10n.profileUpdatedSuccessfully, Colors.green);
      } else {
        _showSnackBar(context, l10n.errorOops, colors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final UserModel? user = ref.watch(authControllerProvider).value;
    final AsyncValue<dynamic> staticDataAsync = ref.watch(
      filterStaticDataProvider,
    );

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.personalInfo,
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
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_outlined,
              color: _isEditing ? colors.error : colors.primary,
            ),
            onPressed: () {
              if (_isEditing) {
                _nameController.text = user.fullName;
                _emailController.text = user.email;
                _phoneController.text = user.phoneNumber ?? '';
                _addressController.text = user.address ?? '';
                _selectedCity = user.city;
                _selectedLat = user.lat;
                _selectedLng = user.lng;
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          SizedBox(width: Dimensions.spacingSmall),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVerificationCard(user, colors, l10n),

              SizedBox(height: Dimensions.spacingExtraLarge),

              Text(
                l10n.basicInfo,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.w800,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      colors: colors,
                    ),
                    SizedBox(height: Dimensions.spacingLarge),

                    _buildTextField(
                      label: l10n.emailAddress,
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      colors: colors,
                    ),
                    SizedBox(height: Dimensions.spacingLarge),

                    _buildTextField(
                      label: l10n.phoneNumber,
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      colors: colors,
                    ),
                    SizedBox(height: Dimensions.spacingLarge),

                    _buildCityDropdown(l10n, colors, staticDataAsync),
                    SizedBox(height: Dimensions.spacingLarge),

                    _buildMapAddressField(l10n, colors),
                  ],
                ),
              ),

              if (_isEditing) ...[
                SizedBox(height: Dimensions.spacingExtraLarge),
                _buildSaveButton(l10n, colors),
                SizedBox(height: Dimensions.spacingLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
    UserModel user,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    final bool isVerified = user.profileIsComplete;
    final Color statusColor = isVerified ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_user_rounded
                  : Icons.pending_actions_rounded,
              color: statusColor,
              size: Dimensions.iconLarge,
            ),
          ),
          SizedBox(width: Dimensions.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.identityVerification,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: Dimensions.spacingTiny),
                Text(
                  isVerified ? l10n.verified : l10n.unverified,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                ),
              ),
              onPressed: () => context.push(RoutePaths.completeProfile),
              child: Text(
                l10n.completeProfileTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required AppColors colors,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: keyboardType,
          style: TextStyle(
            color: _isEditing ? colors.textPrimary : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: colors.iconGrey),
            filled: true,
            fillColor: _isEditing ? colors.background : colors.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimensions.spacingLarge,
              vertical: Dimensions.spacingMedium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapAddressField(AppLocalizations l10n, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addressOptional,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        GestureDetector(
          onTap: _isEditing ? () => _openMapPicker(colors) : null,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _addressController,
              readOnly: true,
              style: TextStyle(
                color: _isEditing ? colors.textPrimary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: colors.iconGrey,
                ),
                suffixIcon: _isEditing
                    ? Container(
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
                      )
                    : null,
                filled: true,
                fillColor: _isEditing ? colors.background : colors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingLarge,
                  vertical: Dimensions.spacingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.2),
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

  Widget _buildCityDropdown(
    AppLocalizations l10n,
    AppColors colors,
    AsyncValue<dynamic> staticDataAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cityOrRegion,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        staticDataAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => Text(
            'Error loading cities',
            style: TextStyle(color: colors.error),
          ),
          data: (data) {
            final List<dynamic> cities = data.cities;
            final bool cityExists = cities.any(
              (c) => c['id'].toString() == _selectedCity,
            );
            final String? validCity = cityExists ? _selectedCity : null;

            return DropdownButtonFormField<String>(
              value: validCity,
              dropdownColor: colors.surface,
              icon: _isEditing
                  ? Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.iconGrey,
                    )
                  : const SizedBox.shrink(),
              items: cities.map<DropdownMenuItem<String>>((city) {
                return DropdownMenuItem<String>(
                  value: city['id'].toString(),
                  child: Text(
                    city['name'].toString(),
                    style: TextStyle(
                      color: _isEditing
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isEditing
                  ? (val) => setState(() => _selectedCity = val)
                  : null,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.location_city_rounded,
                  color: colors.iconGrey,
                ),
                filled: true,
                fillColor: _isEditing ? colors.background : colors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingLarge,
                  vertical: Dimensions.spacingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, AppColors colors) {
    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.1,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: colors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
        ),
        onPressed: _isLoading ? null : () => _saveChanges(l10n, colors),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                l10n.saveChanges,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
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
