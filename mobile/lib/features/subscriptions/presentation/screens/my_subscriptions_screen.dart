import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/subscription_provider.dart';

class MySubscriptionsScreen extends ConsumerWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final subsAsync = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.mySubscriptions,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.explore);
            }
          },
        ),
      ),
      body: SafeArea(
        child: subsAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 48,
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  style: TextStyle(color: colors.textPrimary),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(mySubscriptionsProvider),
                  child: Text(l10n.retryButton),
                ),
              ],
            ),
          ),
          data: (subs) {
            if (subs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 80,
                      color: colors.iconGrey.withOpacity(0.5),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),
                    Text(
                      l10n.noSubscriptions,
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

            return RefreshIndicator(
              color: colors.primary,
              onRefresh: () async => ref.invalidate(mySubscriptionsProvider),
              child: ListView.separated(
                padding: EdgeInsets.all(Dimensions.spacingLarge),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: subs.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: Dimensions.spacingLarge),
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  final isActive = sub.status == 'active';

                  return GestureDetector(
                    // ARCHITECTURE FIX: Navigate to details screen instead of a basic bottom sheet
                    onTap: () => context.push(
                      RoutePaths.subscriptionDetails,
                      extra: sub,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadiusLarge,
                        ),
                        border: Border.all(
                          color: isActive
                              ? colors.primary.withOpacity(0.5)
                              : colors.iconGrey.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isActive
                                ? colors.primary.withOpacity(0.1)
                                : Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.spacingLarge,
                              vertical: Dimensions.spacingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.primary
                                  : colors.iconGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  Dimensions.borderRadiusLarge - 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sub.planName,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : colors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Dimensions.fontBodyLarge,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Dimensions.spacingSmall,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    isActive
                                        ? l10n.activeSubscription
                                        : l10n.expiredSubscription,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(Dimensions.spacingLarge),
                            child: Row(
                              children: [
                                if (sub.branchLogo != null &&
                                    sub.branchLogo!.isNotEmpty)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.iconGrey.withOpacity(0.1),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(sub.branchLogo!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: colors.background,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.fitness_center_rounded,
                                      color: isActive
                                          ? colors.primary
                                          : colors.iconGrey,
                                    ),
                                  ),
                                SizedBox(width: Dimensions.spacingMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.providerName,
                                        style: TextStyle(
                                          fontSize: Dimensions.fontBodyLarge,
                                          fontWeight: FontWeight.w900,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: Dimensions.spacingTiny),
                                      Text(
                                        '${sub.startDate} ➔ ${sub.endDate}',
                                        style: TextStyle(
                                          fontSize: Dimensions.fontBodySmall,
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: colors.iconGrey,
                                  size: Dimensions.iconSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
