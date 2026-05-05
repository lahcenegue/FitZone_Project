import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// A centralized, premium text input field used across the entire application
/// to ensure a consistent and highly maintainable UI design.
class PremiumTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? icon;
  final AppColors colors;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final int maxLines;

  const PremiumTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.icon,
    required this.colors,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the background color based on interaction state to match PersonalInfoScreen
    final Color backgroundColor = (enabled && !readOnly)
        ? colors.background
        : colors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: Dimensions.fontBodyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Dimensions.spacingSmall),
        ],
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing:
                onTap !=
                null, // Absorb pointer if handled by outer GestureDetector
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              readOnly: readOnly,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              style: TextStyle(
                color: enabled ? colors.textPrimary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: colors.iconGrey,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: icon != null
                    ? Icon(icon, color: colors.iconGrey)
                    : null,
                suffixIcon: suffixIcon,
                errorText: errorText,
                errorMaxLines: 2,
                filled: true,
                fillColor: backgroundColor,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(color: colors.error, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(color: colors.error, width: 2),
                ),
              ),
              validator: validator,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
