import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/auth_intent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/gym_details_model.dart';
import 'gym_section_title.dart';

class GymPlansSection extends ConsumerWidget {
  final List<GymPlan> plans;
  final AppColors colors;
  final int gymId;
  final String gymName; // NEW: Accept Gym Name from parent

  const GymPlansSection({
    super.key,
    required this.plans,
    required this.colors,
    required this.gymId,
    required this.gymName,
  });

  void _savePurchaseIntent(WidgetRef ref, int planId) {
    ref
        .read(authIntentServiceProvider)
        .saveIntent(
          AuthIntent(
            type: AuthIntentType.buyGymSubscription,
            payload: {'gym_id': gymId, 'plan_id': planId},
          ),
        );
  }

  void _showAuthPrompt(
    BuildContext context,
    WidgetRef ref,
    int planId,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.0,
                  height: 5.0,
                  margin: EdgeInsets.only(bottom: Dimensions.spacingLarge),
                  decoration: BoxDecoration(
                    color: colors.iconGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                  ),
                ),
                Icon(
                  Icons.lock_person_rounded,
                  size: Dimensions.iconLarge * 2,
                  color: colors.primary,
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Text(
                  l10n.authRequiredTitle,
                  style: TextStyle(
                    fontSize: Dimensions.fontHeading2,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: Dimensions.spacingSmall),
                Text(
                  l10n.authRequiredSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: Dimensions.spacingExtraLarge),
                SizedBox(
                  width: double.infinity,
                  height: Dimensions.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadius,
                        ),
                      ),
                    ),
                    onPressed: () {
                      _savePurchaseIntent(ref, planId);
                      context.pop();
                      context.push(RoutePaths.login);
                    },
                    child: Text(
                      l10n.login,
                      style: TextStyle(
                        fontSize: Dimensions.fontButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
                SizedBox(
                  width: double.infinity,
                  height: Dimensions.buttonHeight,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadius,
                        ),
                      ),
                    ),
                    onPressed: () {
                      _savePurchaseIntent(ref, planId);
                      context.pop();
                      context.push(RoutePaths.register);
                    },
                    child: Text(
                      l10n.createAccount,
                      style: TextStyle(
                        fontSize: Dimensions.fontButton,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlanDetails(
    BuildContext context,
    WidgetRef ref,
    GymPlan plan,
    NumberFormat format,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimensions.borderRadiusLarge),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Dimensions.spacingMedium,
                    ),
                    child: Container(
                      width: 48.0,
                      height: 5.0,
                      decoration: BoxDecoration(
                        color: colors.iconGrey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spacingLarge,
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.all(Dimensions.spacingLarge),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.primary,
                                colors.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              Dimensions.borderRadiusLarge,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: Dimensions.fontHeading1 * 1.2,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimensions.spacingMedium,
                                      vertical: Dimensions.spacingTiny,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      '${plan.durationDays} ${l10n.days}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Dimensions.fontBodyMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Dimensions.spacingMedium),
                              Text(
                                plan.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: Dimensions.fontBodyMedium,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Dimensions.spacingLarge),

                        Container(
                          padding: EdgeInsets.all(Dimensions.spacingMedium),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.borderRadius,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFFD54F).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFF57F17),
                                size: 28,
                              ),
                              SizedBox(width: Dimensions.spacingMedium),
                              Expanded(
                                child: Text(
                                  '${l10n.earnPoints} ${plan.rewardPoints} ${l10n.points}',
                                  style: TextStyle(
                                    color: const Color(0xFFF57F17),
                                    fontWeight: FontWeight.w800,
                                    fontSize: Dimensions.fontTitleMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Dimensions.spacingExtraLarge),

                        Text(
                          l10n.subscriptionPlans,
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading2,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingMedium),
                        ...plan.features
                            .map(
                              (f) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: Dimensions.spacingMedium,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: EdgeInsets.all(
                                        Dimensions.spacingTiny / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: colors.primary,
                                        size: Dimensions.iconSmall,
                                      ),
                                    ),
                                    SizedBox(width: Dimensions.spacingMedium),
                                    Expanded(
                                      child: Text(
                                        f.name,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: Dimensions.fontBodyLarge,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),

                        SizedBox(height: Dimensions.spacingExtraLarge * 2),
                      ],
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.spacingLarge,
                      Dimensions.spacingMedium,
                      Dimensions.spacingLarge,
                      MediaQuery.of(context).padding.bottom +
                          Dimensions.spacingMedium,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: Dimensions.buttonHeight * 1.2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.borderRadiusLarge,
                              ),
                            ),
                          ),
                          onPressed: () {
                            context.pop();

                            final user = ref.read(authControllerProvider).value;

                            if (user == null) {
                              _showAuthPrompt(
                                context,
                                ref,
                                plan.id,
                                colors,
                                l10n,
                              );
                            } else if (!user.profileIsComplete) {
                              context.push(RoutePaths.completeProfile);
                            } else {
                              // ARCHITECTURE FIX: Pass real gymName dynamically
                              context.push(
                                RoutePaths.checkout,
                                extra: {
                                  'planId': plan.id,
                                  'planName': plan.name,
                                  'price': plan.price,
                                  'rewardPoints': plan.rewardPoints,
                                  'gymName': gymName,
                                },
                              );
                            }
                          },
                          child: Text(
                            '${l10n.subscribeNow} • ${format.format(plan.price)} ${l10n.sar}',
                            style: TextStyle(
                              fontSize: Dimensions.fontButton,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: l10n.localeName,
      symbol: '',
    );

    if (plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GymSectionTitle(title: l10n.subscriptionPlans, colors: colors),
        SizedBox(height: Dimensions.spacingMedium),

        SizedBox(
          height: Dimensions.heightPercent(25.0).clamp(220.0, 260.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: plans.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: Dimensions.spacingMedium),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Container(
                width: Dimensions.widthPercent(70.0).clamp(260.0, 320.0),
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Dimensions.fontHeading2,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.spacingSmall,
                            vertical: Dimensions.spacingTiny,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusPill,
                            ),
                          ),
                          child: Text(
                            '${plan.durationDays} ${l10n.days}',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: Dimensions.fontBodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyMedium,
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currencyFormat.format(plan.price),
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading1 * 1.1,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingTiny),
                        Text(
                          l10n.sar,
                          style: TextStyle(
                            fontSize: Dimensions.fontBodyMedium,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingMedium),
                    SizedBox(
                      width: double.infinity,
                      height: Dimensions.buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.surface,
                          elevation: 4,
                          shadowColor: colors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.borderRadius,
                            ),
                          ),
                        ),
                        onPressed: () => _showPlanDetails(
                          context,
                          ref,
                          plan,
                          currencyFormat,
                          l10n,
                        ),
                        child: Text(
                          l10n.subscribeNow,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.fontBodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
