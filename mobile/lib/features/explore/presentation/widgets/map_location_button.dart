import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';

class MapLocationButton extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onLocationTap;

  const MapLocationButton({
    super.key,
    required this.colors,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimensions.customButtonSize,
      height: Dimensions.customButtonSize,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            spreadRadius: Dimensions.shadowSpreadRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onLocationTap,
          child: Icon(
            Icons.my_location,
            color: colors.primary,
            size: Dimensions.iconMedium,
          ),
        ),
      ),
    );
  }
}
