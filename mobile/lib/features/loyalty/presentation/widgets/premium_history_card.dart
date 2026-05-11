import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class PremiumHistoryCard extends StatelessWidget {
  final String title;
  final String date;
  final String statusLabel;
  final String? releaseDateText;
  final String amount;
  final IconData icon;
  final Color themeColor;
  final AppColors colors;
  final VoidCallback? onTap;

  const PremiumHistoryCard({
    super.key,
    required this.title,
    required this.date,
    required this.statusLabel,
    this.releaseDateText,
    required this.amount,
    required this.icon,
    required this.themeColor,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSimpleRow =
        releaseDateText == null || releaseDateText!.isEmpty;
    final bool hasAmount = amount.isNotEmpty && amount != '+' && amount != '-';

    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(Dimensions.spacingMedium),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: colors.iconGrey.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: isSimpleRow
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              // 1. Icon Section
              Container(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: themeColor,
                  size: Dimensions.iconMedium,
                ),
              ),
              SizedBox(width: Dimensions.spacingMedium),

              // 2. Info Section (Title & Date)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: Dimensions.fontBodyLarge,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isSimpleRow) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: themeColor.withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              releaseDateText!,
                              style: TextStyle(
                                fontSize: 11,
                                color: themeColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Adaptive Right Side (Amount & Status)
              SizedBox(width: Dimensions.spacingSmall),
              Column(
                // ARCHITECTURE FIX: Changed from CrossAxisAlignment.end to center
                // to perfectly align the amount and the status pill relative to each other.
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasAmount) ...[
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyLarge,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                    SizedBox(height: 6),
                  ],
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasAmount ? 8 : 12,
                      vertical: hasAmount ? 2 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: hasAmount ? 10 : 12,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
