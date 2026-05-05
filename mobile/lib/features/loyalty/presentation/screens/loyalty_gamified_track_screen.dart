import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../widgets/loyalty_reward_sheet.dart';

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
    _logger.info('Initializing Premium Clean Vertical Track Animation.');

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

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final l10n = AppLocalizations.of(context)!;

    final walletAsync = ref.watch(loyaltyWalletProvider);
    final roadmapAsync = ref.watch(loyaltyRoadmapProvider);
    // ARCHITECTURE FIX: Fetch all milestones to determine exact status
    final userMilestonesAsync = ref.watch(allUserMilestonesProvider);

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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => _buildErrorUI(colors, l10n),
          data: (wallet) {
            return roadmapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => _buildErrorUI(colors, l10n),
              data: (milestones) {
                return userMilestonesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => _buildErrorUI(colors, l10n),
                  data: (userMilestones) {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.spacingLarge,
                          ),
                          child: _buildTopProgressCard(
                            context,
                            colors,
                            l10n,
                            wallet,
                          ),
                        ),
                        Expanded(
                          child: _buildVerticalTrackCanvas(
                            context,
                            colors,
                            l10n,
                            wallet.lifetimePoints,
                            milestones,
                            userMilestones,
                            isRTL,
                          ),
                        ),
                      ],
                    );
                  },
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

  Widget _buildTopProgressCard(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    WalletSummary wallet,
  ) {
    if (wallet.nextMilestone == null) return const SizedBox.shrink();

    final int requiredPoints = wallet.nextMilestone!.requiredPoints;
    final int remainingPoints = requiredPoints - wallet.lifetimePoints > 0
        ? requiredPoints - wallet.lifetimePoints
        : 0;
    final double progressPct = wallet.lifetimePoints / requiredPoints;

    return Container(
      margin: EdgeInsets.only(
        top: Dimensions.spacingMedium,
        bottom: Dimensions.spacingLarge,
      ),
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: colors.iconGrey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: Dimensions.spacingLarge,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.levelProgress,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: Dimensions.fontTitleMedium,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingMedium,
                  vertical: Dimensions.spacingTiny,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
                child: Text(
                  wallet.nextMilestone!.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: Dimensions.fontBodySmall,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),
          Directionality(
            textDirection: TextDirection.ltr,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusPill),
              child: LinearProgressIndicator(
                value: progressPct.clamp(0.0, 1.0),
                minHeight: Dimensions.spacingMedium,
                backgroundColor: colors.iconGrey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${wallet.lifetimePoints} / $requiredPoints',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: Dimensions.fontBodyMedium,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$remainingPoints ${l10n.pointsToNextMilestone}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: Dimensions.fontBodySmall,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTrackCanvas(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    int lifetimePoints,
    List<LoyaltyMilestone> apiMilestones,
    List<UserMilestone> userMilestones,
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
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

              // ARCHITECTURE FIX: Extract correct 3-stage state for each node
              final userMilestone = userMilestones.firstWhereOrNull(
                (um) => um.milestone.id == milestone.id,
              );
              final bool isUnlocked =
                  lifetimePoints >= milestone.requiredLifetimePoints;
              final bool isClaimed = userMilestone?.isClaimed ?? false;
              final bool isConsumed = userMilestone?.isConsumed ?? false;

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
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
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
                    milestone,
                    userMilestone,
                    isUnlocked,
                    isClaimed,
                    isConsumed,
                    colors,
                    l10n,
                  ),
                ),
              );
            }),

            ...List.generate(trackNodes.length, (index) {
              if (index == 0) return const SizedBox.shrink();

              final milestone = trackNodes[index];
              final offset = nodeOffsets[index];
              final userMilestone = userMilestones.firstWhereOrNull(
                (um) => um.milestone.id == milestone.id,
              );

              final bool isUnlocked =
                  lifetimePoints >= milestone.requiredLifetimePoints;
              final bool isClaimed = userMilestone?.isClaimed ?? false;

              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: isUnlocked ? colors.primary : colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked
                            ? colors.surface
                            : colors.iconGrey.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        if (isUnlocked)
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: isUnlocked
                        ? Icon(
                            isClaimed
                                ? Icons.check_rounded
                                : Icons.star_rounded,
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
      ),
    );
  }

  Widget _buildPremiumMilestoneCard(
    LoyaltyMilestone milestone,
    UserMilestone? userMilestone,
    bool isUnlocked,
    bool isClaimed,
    bool isConsumed,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    // Dynamic styles based on 3-stage lifecycle
    Color borderColor;
    Color iconColor;
    IconData iconData;
    String statusText;

    if (!isUnlocked) {
      borderColor = colors.iconGrey.withValues(alpha: 0.15);
      iconColor = colors.iconGrey;
      iconData = Icons.lock_rounded;
      statusText = l10n.tapToSeeReward;
    } else if (!isClaimed) {
      borderColor = colors.warning; // Highlight to claim!
      iconColor = colors.warning;
      iconData = Icons.redeem_rounded;
      statusText = l10n.claimRewardBtn;
    } else if (!isConsumed) {
      borderColor = colors.primary.withValues(alpha: 0.5);
      iconColor = colors.primary;
      iconData = Icons.inventory_2_rounded;
      statusText = l10n.claimedDesc;
    } else {
      borderColor = colors.success.withValues(alpha: 0.5);
      iconColor = colors.success;
      iconData = Icons.check_circle_rounded;
      statusText = l10n.consumedDesc;
    }

    return GestureDetector(
      onTap: () {
        _logger.info('User tapped milestone card: ${milestone.title}');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => LoyaltyRewardSheet(
            milestone: milestone,
            userMilestone: userMilestone,
            isUnlocked: isUnlocked,
            isFromWallet:
                false, // Ensures it only shows "Claim" or routing to wallet
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
            width: isUnlocked && !isConsumed ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
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
                color: isUnlocked
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
                            color: isUnlocked && !isClaimed
                                ? colors.warning
                                : colors.primary,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingTiny),
                      Icon(
                        Icons.ads_click_rounded,
                        size: Dimensions.iconSmall,
                        color: isUnlocked && !isClaimed
                            ? colors.warning
                            : colors.primary,
                      ),
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

// --- LAYER 1: Line Painter ---
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

// --- LAYER 3: Perfect Avatar Tooltip Painter ---
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
    // Inner pulse dot on the line
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
