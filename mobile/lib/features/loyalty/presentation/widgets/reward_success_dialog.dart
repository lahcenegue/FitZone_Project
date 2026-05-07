import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';

class RewardSuccessDialog extends StatefulWidget {
  final LoyaltyMilestone milestone;
  final AppColors colors;
  final AppLocalizations l10n;

  const RewardSuccessDialog({
    super.key,
    required this.milestone,
    required this.colors,
    required this.l10n,
  });

  @override
  State<RewardSuccessDialog> createState() => _RewardSuccessDialogState();
}

class _RewardSuccessDialogState extends State<RewardSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(Dimensions.spacingLarge),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: Dimensions.iconLarge * 3),
            padding: EdgeInsets.fromLTRB(
              Dimensions.spacingExtraLarge,
              Dimensions.spacingExtraLarge * 4,
              Dimensions.spacingExtraLarge,
              Dimensions.spacingExtraLarge,
            ),
            decoration: BoxDecoration(
              color: widget.colors.surface,
              borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.shadow.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.l10n.successUnboxedTitle,
                  style: TextStyle(
                    fontSize: Dimensions.fontHeading1,
                    fontWeight: FontWeight.w900,
                    color: widget.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.spacingSmall),
                Text(
                  widget.l10n.successUnboxedDesc,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    color: widget.colors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.spacingExtraLarge),

                // Reward Highlight Box
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingMedium),
                  decoration: BoxDecoration(
                    color: widget.colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                    border: Border.all(
                      color: widget.colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Dimensions.spacingSmall),
                        decoration: BoxDecoration(
                          color: widget.colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.featured_play_list_rounded,
                          color: widget.colors.primary,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingMedium),
                      Expanded(
                        child: Text(
                          widget.milestone.reward?.name ??
                              widget.milestone.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: Dimensions.fontTitleMedium,
                            color: widget.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(RoutePaths.rewardsHistory);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colors.primary,
                      foregroundColor: widget.colors.surface,
                      padding: EdgeInsets.symmetric(
                        vertical: Dimensions.spacingMedium * 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadiusLarge,
                        ),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      widget.l10n.goToWalletBtn,
                      style: TextStyle(
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.colors.textSecondary,
                  ),
                  child: Text(
                    widget.l10n.continueDiscoveringBtn,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimensions.fontBodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Premium overlapping animated gift icon
          Positioned(
            top: 0,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: EdgeInsets.all(Dimensions.spacingLarge * 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.colors.warning, widget.colors.star],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.colors.surface, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colors.warning.withValues(alpha: 0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.redeem_rounded,
                  size: Dimensions.iconLarge * 3,
                  color: widget.colors.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
