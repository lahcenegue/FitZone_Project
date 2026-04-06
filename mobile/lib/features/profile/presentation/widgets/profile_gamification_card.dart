import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileGamificationCard extends StatelessWidget {
  final UserModel user;
  final AppColors colors;
  final AppLocalizations l10n;

  const ProfileGamificationCard({
    super.key,
    required this.user,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    const int targetPoints = 500;
    final int currentPoints = user.pointsBalance;
    final double progress = (currentPoints / targetPoints).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: Dimensions.iconLarge * 4.0,
            height: Dimensions.iconLarge * 4.0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: value,
                    backgroundColor: colors.iconGrey.withOpacity(0.15),
                    progressColor: colors.star,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.all(Dimensions.spacingMedium),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPoints.toString(),
                              style: TextStyle(
                                fontSize: Dimensions.fontHeading1 * 1.2,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '/ $targetPoints',
                              style: TextStyle(
                                fontSize: Dimensions.fontBodyMedium,
                                fontWeight: FontWeight.w800,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: Dimensions.spacingLarge),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.loyaltyOverview,
                  style: TextStyle(
                    fontSize: Dimensions.fontHeading2,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: Dimensions.spacingSmall),
                Text(
                  l10n.pointsToPremium,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    color: colors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 14.0;
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bgPaint);

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
