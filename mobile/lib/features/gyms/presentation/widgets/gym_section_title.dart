import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';

class GymSectionTitle extends StatelessWidget {
  final String title;
  final AppColors colors;

  const GymSectionTitle({super.key, required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: Dimensions.fontHeading3,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }
}
