import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppColors colors;

  const StatSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimensions.screenWidth * 0.45,
      padding: EdgeInsets.all(Dimensions.spacingMedium),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Dimensions.iconMedium),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            title,
            style: TextStyle(
              fontSize: Dimensions.fontBodySmall,
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: Dimensions.spacingTiny),
          Text(
            value,
            style: TextStyle(
              fontSize: Dimensions.fontTitleMedium,
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
