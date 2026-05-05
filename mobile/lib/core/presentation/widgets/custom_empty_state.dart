import 'package:fitzone/core/theme/app_colors.dart';
import 'package:fitzone/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';

class CustomEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final AppColors colors;

  const CustomEmptyState({
    super.key,
    required this.message,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: Dimensions.iconLarge * 3,
            color: colors.iconGrey.withOpacity(0.3),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            message,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: Dimensions.fontBodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
