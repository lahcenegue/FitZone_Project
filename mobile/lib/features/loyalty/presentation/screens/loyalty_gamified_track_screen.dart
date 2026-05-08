import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../widgets/track_reward_sheet.dart';

class LoyaltyGamifiedTrackScreen extends ConsumerStatefulWidget {
  const LoyaltyGamifiedTrackScreen({super.key});

  @override
  ConsumerState<LoyaltyGamifiedTrackScreen> createState() =>
      _LoyaltyGamifiedTrackScreenState();
}

class _LoyaltyGamifiedTrackScreenState
    extends ConsumerState<LoyaltyGamifiedTrackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  static final Logger _logger = Logger('LoyaltyGamifiedTrackScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing Premium Gamified Track.');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _logger.info('User triggered manual refresh of Gamified Track.');
    ref.invalidate(loyaltyWalletProvider);
    ref.invalidate(loyaltyRoadmapProvider);

    try {
      await ref.read(loyaltyWalletProvider.future);
    } catch (_) {}

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final walletAsync = ref.watch(loyaltyWalletProvider);
    final roadmapAsync = ref.watch(loyaltyRoadmapProvider);

    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.achievementTrack,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        bottom: false,
        child: walletAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
          error: (e, s) => _buildErrorUI(colors, l10n),
          data: (wallet) {
            return roadmapAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
              error: (e, s) => _buildErrorUI(colors, l10n),
              data: (milestones) {
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: colors.primary,
                  backgroundColor: colors.surface,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.spacingLarge,
                          ),
                          child: _buildPremiumOutOftheBoxCard(
                            context,
                            colors,
                            l10n,
                            wallet,
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildVerticalTrackCanvas(
                          context,
                          colors,
                          l10n,
                          wallet.lifetimePoints,
                          milestones,
                          isRTL,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorUI(AppColors colors, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: Dimensions.iconLarge * 3,
            color: colors.error.withValues(alpha: 0.5),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            l10n.errorLoadingDetails,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Masterpiece: Live Animated Premium Card
  Widget _buildPremiumOutOftheBoxCard(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    WalletSummary wallet,
  ) {
    final NextMilestone? next = wallet.nextMilestone;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(
                top: Dimensions.spacingMedium,
                bottom: Dimensions.spacingLarge,
              ),
              padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge,
                ),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.15 * value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.08 * value),
                    blurRadius: 30,
                    spreadRadius: 5 * value,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Section: Points Overview with Counter Animation
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.spendablePoints,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: Dimensions.fontBodyMedium,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimensions.spacingSmall),
                      _buildAnimatedCounter(
                        wallet.spendablePoints,
                        colors.success,
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  color: colors.iconGrey.withValues(alpha: 0.2),
                  width: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Tooltip(
                            message: l10n.lifetimePointsDesc,
                            triggerMode: TooltipTriggerMode.tap,
                            decoration: BoxDecoration(
                              color: colors.textPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              color: colors.surface,
                              fontSize: Dimensions.fontBodyMedium,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: Dimensions.iconSmall,
                              color: colors.iconGrey,
                            ),
                          ),
                          SizedBox(width: Dimensions.spacingTiny),
                          Text(
                            l10n.lifetimePoints,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: Dimensions.fontBodyMedium,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimensions.spacingSmall),
                      _buildAnimatedCounter(
                        wallet.lifetimePoints,
                        colors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (next != null) ...[
            SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

            // Middle Section: Current vs Next Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentLevel,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Text(
                      wallet.currentMilestoneTitle.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: Dimensions.fontHeading3,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.nextTier,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodySmall,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spacingMedium,
                        vertical: Dimensions.spacingTiny,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: colors.primary,
                            size: Dimensions.iconSmall,
                          ),
                          SizedBox(width: Dimensions.spacingTiny),
                          Text(
                            next.title.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: Dimensions.fontBodySmall,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: Dimensions.spacingExtraLarge),

            // Bottom Section: Custom Glowing Animated Progress Bar
            _buildCustomAnimatedProgressBar(next.progressPct, colors),

            SizedBox(height: Dimensions.spacingMedium),

            // Points Remaining Info
            Center(
              child: _buildAnimatedRemainingCounter(
                next.pointsToNextMilestone,
                colors,
                l10n,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedCounter(int targetValue, Color color) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.fontHeading1,
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRemainingCounter(
    int targetValue,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(
        begin: targetValue + 500,
        end: targetValue,
      ), // Count down effect
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Text(
          '$value ${l10n.pointsNeededToUnlock}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Dimensions.fontBodyMedium,
            color: colors.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildCustomAnimatedProgressBar(double progressPct, AppColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double clampedProgress = (progressPct / 100).clamp(0.0, 1.0);
        final double activeWidth = width * clampedProgress;
        final double thumbSize = Dimensions.iconLarge * 1.5;

        return SizedBox(
          height: thumbSize,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: Dimensions.spacingMedium,
                width: width,
                decoration: BoxDecoration(
                  color: colors.iconGrey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: activeWidth),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeOutQuart,
                builder: (context, animatedWidth, child) {
                  return Container(
                    height: Dimensions.spacingMedium,
                    width: animatedWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.5),
                          colors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.0,
                  end: activeWidth > thumbSize ? activeWidth - thumbSize : 0,
                ),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeOutQuart,
                builder: (context, animatedLeft, child) {
                  return Positioned(
                    left: animatedLeft,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: progressPct),
                              duration: const Duration(milliseconds: 2000),
                              builder: (context, val, _) {
                                return Text(
                                  '${val.toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: Dimensions.fontBodySmall,
                                    color: colors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalTrackCanvas(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    int lifetimePoints,
    List<LoyaltyMilestone> apiMilestones,
    bool isRTL,
  ) {
    if (apiMilestones.isEmpty) return const SizedBox.shrink();

    final List<LoyaltyMilestone> trackNodes = [
      const LoyaltyMilestone(
        id: 0,
        title: 'Start',
        requiredLifetimePoints: 0,
        description: '',
      ),
      ...apiMilestones,
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final double lineOffsetFromEdge = Dimensions.spacingExtraLarge * 3.8;
    final double lineX = isRTL
        ? (screenWidth - lineOffsetFromEdge)
        : lineOffsetFromEdge;

    final double nodeSpacingY = Dimensions.spacingExtraLarge * 5.5;
    final double paddingTop = Dimensions.spacingLarge;
    final double paddingBottom = Dimensions.spacingExtraLarge * 6;

    final double totalHeight =
        (trackNodes.length * nodeSpacingY) + paddingTop + paddingBottom;
    final double circleSize = Dimensions.iconLarge * 1.5;

    final List<Offset> nodeOffsets = [];
    for (int i = 0; i < trackNodes.length; i++) {
      final double y = paddingTop + (i * nodeSpacingY);
      nodeOffsets.add(Offset(lineX, y));
    }

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(screenWidth, totalHeight),
                  painter: _VerticalLinePainter(
                    nodes: trackNodes,
                    nodeOffsets: nodeOffsets,
                    userPoints: lifetimePoints,
                    colors: colors,
                    animationProgress: _progressAnimation.value,
                  ),
                );
              },
            ),
          ),
          ...List.generate(trackNodes.length, (index) {
            final milestone = trackNodes[index];
            final offset = nodeOffsets[index];
            final String status =
                milestone.userMilestoneData?.status ?? 'locked';

            if (index == 0) {
              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Container(
                    width: Dimensions.iconLarge * 1.3,
                    height: Dimensions.iconLarge * 1.3,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 4),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: colors.surface,
                      size: Dimensions.iconSmall,
                    ),
                  ),
                ),
              );
            }

            final double cardGap = Dimensions.spacingSmall;

            return Positioned(
              left: isRTL
                  ? Dimensions.spacingLarge
                  : lineX + (circleSize / 2) + cardGap,
              right: isRTL
                  ? (screenWidth - lineX) + (circleSize / 2) + cardGap
                  : Dimensions.spacingLarge,
              top: offset.dy,
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: _buildPremiumMilestoneCard(
                  milestone: milestone,
                  status: status,
                  colors: colors,
                  l10n: l10n,
                  currentLifetimePoints: lifetimePoints,
                ),
              ),
            );
          }),
          ...List.generate(trackNodes.length, (index) {
            if (index == 0) return const SizedBox.shrink();

            final milestone = trackNodes[index];
            final offset = nodeOffsets[index];
            final String status =
                milestone.userMilestoneData?.status ?? 'locked';
            final bool isUnlockedOrBeyond = status != 'locked';

            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: isUnlockedOrBeyond ? colors.primary : colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlockedOrBeyond
                          ? colors.surface
                          : colors.iconGrey.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      if (isUnlockedOrBeyond)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: isUnlockedOrBeyond
                      ? Icon(
                          Icons.check_rounded,
                          color: colors.surface,
                          size: Dimensions.iconMedium,
                        )
                      : null,
                ),
              ),
            );
          }),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(screenWidth, totalHeight),
                  painter: _AvatarPainter(
                    nodes: trackNodes,
                    nodeOffsets: nodeOffsets,
                    userPoints: lifetimePoints,
                    colors: colors,
                    animationProgress: _progressAnimation.value,
                    l10n: l10n,
                    isRTL: isRTL,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMilestoneCard({
    required LoyaltyMilestone milestone,
    required String status,
    required AppColors colors,
    required AppLocalizations l10n,
    required int currentLifetimePoints,
  }) {
    Color borderColor;
    Color iconColor;
    IconData iconData;
    String statusText;

    if (status == 'locked') {
      borderColor = colors.iconGrey.withValues(alpha: 0.15);
      iconColor = colors.iconGrey;
      iconData = Icons.lock_rounded;
      statusText = l10n.trackLockedTitle;
    } else if (status == 'unlocked') {
      borderColor = colors.warning;
      iconColor = colors.warning;
      iconData = Icons.redeem_rounded;
      statusText = l10n.trackUnlockedTitle;
    } else {
      borderColor = colors.primary.withValues(alpha: 0.5);
      iconColor = colors.primary;
      iconData = Icons.inventory_2_rounded;
      statusText = l10n.trackClaimedTitle;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => TrackRewardSheet(
            milestone: milestone,
            userMilestoneData: milestone.userMilestoneData,
            currentLifetimePoints: currentLifetimePoints,
            colors: colors,
            l10n: l10n,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(Dimensions.spacingSmall),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: borderColor,
            width: status == 'unlocked' ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: status == 'unlocked'
                  ? borderColor.withValues(alpha: 0.1)
                  : colors.shadow.withValues(alpha: 0.03),
              blurRadius: Dimensions.spacingMedium,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.spacingMedium),
              decoration: BoxDecoration(
                color: status != 'locked'
                    ? iconColor.withValues(alpha: 0.1)
                    : colors.iconGrey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: Dimensions.iconMedium,
              ),
            ),
            SizedBox(width: Dimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: Dimensions.fontHeading3,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    '${milestone.requiredLifetimePoints} ${l10n.pts}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: Dimensions.fontBodyMedium,
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingSmall),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: Dimensions.fontBodySmall,
                            color: status == 'unlocked'
                                ? colors.warning
                                : (status == 'locked'
                                      ? colors.textSecondary
                                      : colors.success),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status == 'unlocked') ...[
                        SizedBox(width: Dimensions.spacingTiny),
                        Icon(
                          Icons.ads_click_rounded,
                          size: Dimensions.iconSmall,
                          color: colors.warning,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (_VerticalLinePainter and _AvatarPainter remain identical)
class _VerticalLinePainter extends CustomPainter {
  final List<LoyaltyMilestone> nodes;
  final List<Offset> nodeOffsets;
  final int userPoints;
  final AppColors colors;
  final double animationProgress;

  _VerticalLinePainter({
    required this.nodes,
    required this.nodeOffsets,
    required this.userPoints,
    required this.colors,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeOffsets.length < 2) return;

    final double lineWidth = Dimensions.spacingSmall * 0.8;

    final Paint inactivePaint = Paint()
      ..color = colors.iconGrey.withValues(alpha: 0.2)
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final Paint activeGlow = Paint()
      ..color = colors.primary.withValues(alpha: 0.3)
      ..strokeWidth = lineWidth * 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final double startX = nodeOffsets.first.dx;
    final double startY = nodeOffsets.first.dy;
    final double endY = nodeOffsets.last.dy;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, endY),
      inactivePaint,
    );

    double targetY = startY;
    bool isPlaced = false;

    for (int i = 0; i < nodeOffsets.length - 1; i++) {
      final int startP = nodes[i].requiredLifetimePoints;
      final int endP = nodes[i + 1].requiredLifetimePoints;

      if (!isPlaced) {
        if (userPoints >= endP) {
          targetY = nodeOffsets[i + 1].dy;
        } else if (userPoints > startP && userPoints < endP) {
          final double frac = (userPoints - startP) / (endP - startP);
          targetY =
              nodeOffsets[i].dy +
              ((nodeOffsets[i + 1].dy - nodeOffsets[i].dy) * frac);
          isPlaced = true;
        } else {
          isPlaced = true;
        }
      }
    }

    final double currentAnimatedY =
        startY + ((targetY - startY) * animationProgress);

    if (currentAnimatedY > startY) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, currentAnimatedY),
        activeGlow,
      );
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, currentAnimatedY),
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalLinePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.userPoints != userPoints;
  }
}

class _AvatarPainter extends CustomPainter {
  final List<LoyaltyMilestone> nodes;
  final List<Offset> nodeOffsets;
  final int userPoints;
  final AppColors colors;
  final double animationProgress;
  final AppLocalizations l10n;
  final bool isRTL;

  _AvatarPainter({
    required this.nodes,
    required this.nodeOffsets,
    required this.userPoints,
    required this.colors,
    required this.animationProgress,
    required this.l10n,
    required this.isRTL,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeOffsets.length < 2 || animationProgress == 0) return;

    final double startX = nodeOffsets.first.dx;
    final double startY = nodeOffsets.first.dy;

    double targetY = startY;
    bool isPlaced = false;

    for (int i = 0; i < nodeOffsets.length - 1; i++) {
      final int startP = nodes[i].requiredLifetimePoints;
      final int endP = nodes[i + 1].requiredLifetimePoints;

      if (!isPlaced) {
        if (userPoints >= endP) {
          targetY = nodeOffsets[i + 1].dy;
        } else if (userPoints > startP && userPoints < endP) {
          final double frac = (userPoints - startP) / (endP - startP);
          targetY =
              nodeOffsets[i].dy +
              ((nodeOffsets[i + 1].dy - nodeOffsets[i].dy) * frac);
          isPlaced = true;
        } else {
          isPlaced = true;
        }
      }
    }

    final double currentAnimatedY =
        startY + ((targetY - startY) * animationProgress);
    final Offset avatarPosition = Offset(startX, currentAnimatedY);

    _drawAvatarTooltip(canvas, avatarPosition);
  }

  void _drawAvatarTooltip(Canvas canvas, Offset position) {
    final Paint glowPaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(position, Dimensions.iconSmall, glowPaint);

    final Paint dotPaint = Paint()..color = colors.surface;
    canvas.drawCircle(position, Dimensions.iconSmall * 0.8, dotPaint);

    final Paint corePaint = Paint()..color = colors.primary;
    canvas.drawCircle(position, Dimensions.iconSmall * 0.4, corePaint);

    if (animationProgress > 0.9) {
      final textStyle = TextStyle(
        color: colors.surface,
        fontWeight: FontWeight.w900,
        fontSize: Dimensions.fontBodyMedium,
        height: 1.4,
      );

      final TextSpan textSpan = TextSpan(
        text: '${l10n.youAreHere}\n$userPoints ${l10n.pts}',
        style: textStyle,
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      final double paddingX = Dimensions.spacingLarge;
      final double paddingY = Dimensions.spacingMedium;
      final double bgWidth = textPainter.width + paddingX;
      final double bgHeight = textPainter.height + paddingY;

      final double gap = Dimensions.spacingMedium;
      final double pointerSize = Dimensions.spacingSmall;

      final double tooltipX = isRTL
          ? position.dx + gap
          : position.dx - bgWidth - gap;
      final double tooltipY = position.dy - (bgHeight / 2);

      final Rect bgRect = Rect.fromLTWH(tooltipX, tooltipY, bgWidth, bgHeight);
      final Paint bgPaint = Paint()
        ..color = colors.primary
        ..style = PaintingStyle.fill;
      final RRect rRect = RRect.fromRectAndRadius(
        bgRect,
        Radius.circular(Dimensions.borderRadius),
      );

      canvas.drawRRect(
        rRect.shift(const Offset(0, 4)),
        Paint()
          ..color = colors.shadow.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      canvas.drawRRect(rRect, bgPaint);

      final Path pointer = Path();
      if (isRTL) {
        pointer.moveTo(bgRect.left, bgRect.center.dy - pointerSize);
        pointer.lineTo(bgRect.left - pointerSize, bgRect.center.dy);
        pointer.lineTo(bgRect.left, bgRect.center.dy + pointerSize);
      } else {
        pointer.moveTo(bgRect.right, bgRect.center.dy - pointerSize);
        pointer.lineTo(bgRect.right + pointerSize, bgRect.center.dy);
        pointer.lineTo(bgRect.right, bgRect.center.dy + pointerSize);
      }
      pointer.close();
      canvas.drawPath(pointer, bgPaint);

      textPainter.paint(
        canvas,
        Offset(tooltipX + (paddingX / 2), tooltipY + (paddingY / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.userPoints != userPoints;
  }
}
