import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';

class TransactionItemCard extends StatelessWidget {
  final FinancialTransaction transaction;
  final AppColors colors;
  final AppLocalizations l10n;

  const TransactionItemCard({
    super.key,
    required this.transaction,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = !transaction.amount.trim().startsWith('-');
    final DateTime parsedDate =
        DateTime.tryParse(transaction.createdAt)?.toLocal() ?? DateTime.now();

    // Fetch the current language code (e.g., 'ar' or 'en') for localized dates
    final String currentLocale = Localizations.localeOf(context).languageCode;

    IconData txIcon;
    Color txColor;
    if (transaction.type == 'withdrawal') {
      txIcon = Icons.arrow_upward_rounded;
      txColor = colors.error;
    } else if (transaction.type == 'refund') {
      txIcon = Icons.refresh_rounded;
      txColor = colors.warning;
    } else {
      txIcon = Icons.arrow_downward_rounded;
      txColor = colors.success;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            decoration: BoxDecoration(
              color: txColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(txIcon, color: txColor, size: Dimensions.iconMedium),
          ),
          SizedBox(width: Dimensions.spacingMedium),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: Dimensions.fontBodyMedium,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: Dimensions.spacingTiny),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                    currentLocale,
                  ).format(parsedDate),
                  style: TextStyle(
                    fontSize: Dimensions.fontBodySmall,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: Dimensions.spacingMedium),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                transaction.amount,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: Dimensions.fontBodyLarge,
                  color: isPositive ? colors.success : colors.textPrimary,
                ),
              ),
              SizedBox(height: Dimensions.spacingTiny),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;

    switch (transaction.status) {
      case 'completed':
        bgColor = colors.success.withOpacity(0.1);
        textColor = colors.success;
        text = l10n.statusCompleted;
        break;
      case 'pending':
        bgColor = colors.warning.withOpacity(0.1);
        textColor = colors.warning;
        text = l10n.statusPending;
        break;
      default:
        bgColor = colors.error.withOpacity(0.1);
        textColor = colors.error;
        text = l10n.statusFailed;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingMedium,
        vertical: Dimensions.spacingTiny,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Dimensions.fontBodySmall * 0.9,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}
