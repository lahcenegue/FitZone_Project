import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/custom_empty_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../widgets/dynamic_filter_row.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/loyalty_reward_sheet.dart';

class RewardsHistoryScreen extends ConsumerStatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  ConsumerState<RewardsHistoryScreen> createState() =>
      _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends ConsumerState<RewardsHistoryScreen> {
  final Logger _logger = Logger('RewardsHistoryScreen');
  final ScrollController _scrollController = ScrollController();

  static const int _itemsPerPage = 15;

  final List<UserMilestone> _rewards = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _selectedFilter =
      'all'; // ARCHITECTURE FIX: Supports 'all', 'claimed', 'consumed'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRewards(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _fetchRewards();
      }
    }
  }

  Future<void> _fetchRewards({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _rewards.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      final statusParam = _selectedFilter == 'all' ? null : _selectedFilter;

      final response = await apiService.getMyMilestones(
        limit: _itemsPerPage,
        page: _page,
        status: statusParam,
      );

      if (mounted) {
        setState(() {
          _rewards.addAll(response.results);
          _hasMore = response.next != null;
          if (_hasMore) _page++;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch rewards history', e, stackTrace);
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorOops);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    _fetchRewards(refresh: true);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ref.read(appThemeProvider).error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final Map<String, String> filterOptions = {
      'all': l10n.all,
      'claimed': l10n.rewardAvailable,
      'consumed': l10n.rewardConsumed,
    };

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.myRewards,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimensions.spacingMedium),

            _buildSummaryCards(colors, l10n),
            SizedBox(height: Dimensions.spacingLarge),

            DynamicFilterRow(
              filters: filterOptions,
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterChanged,
              colors: colors,
            ),
            SizedBox(height: Dimensions.spacingMedium),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    )
                  : _rewards.isEmpty
                  ? CustomEmptyState(
                      message: l10n.noRewards,
                      icon: Icons.card_giftcard_rounded,
                      colors: colors,
                    )
                  : _buildRewardsList(colors, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AppColors colors, AppLocalizations l10n) {
    final summaryAsync = ref.watch(rewardsSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Row(
            children: [
              StatSummaryCard(
                title: l10n.rewardAvailable,
                value: summary.totalAvailable.toString(),
                icon: Icons.redeem_rounded,
                color: colors.success,
                colors: colors,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.rewardConsumed,
                value: summary.totalConsumed.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: colors.iconGrey,
                colors: colors,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardsList(AppColors colors, AppLocalizations l10n) {
    final String currentLocale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.spacingExtraLarge),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          child: ListView.separated(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: _rewards.length + (_hasMore ? 1 : 0),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colors.iconGrey.withOpacity(0.1),
              indent: Dimensions.spacingExtraLarge * 2,
            ),
            itemBuilder: (context, index) {
              if (index == _rewards.length) {
                return Padding(
                  padding: EdgeInsets.all(Dimensions.spacingLarge),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                );
              }

              final reward = _rewards[index];
              final String dateString = reward.claimedAt ?? reward.unlockedAt;
              final DateTime earnedDate =
                  DateTime.tryParse(dateString)?.toLocal() ?? DateTime.now();

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => LoyaltyRewardSheet(
                        milestone: reward.milestone,
                        userMilestoneWallet:
                            reward, // Loaded from wallet, has payload
                        isFromWallet: true,
                        colors: colors,
                        l10n: l10n,
                      ),
                    );
                  },
                  child: Padding(
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
                            color: reward.isConsumed
                                ? colors.iconGrey.withOpacity(0.1)
                                : colors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            color: reward.isConsumed
                                ? colors.iconGrey
                                : colors.success,
                            size: Dimensions.iconMedium,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.milestone.reward?.name ??
                                    reward.milestone.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Dimensions.fontBodyMedium,
                                  color: reward.isConsumed
                                      ? colors.textSecondary
                                      : colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: Dimensions.spacingTiny),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                  currentLocale,
                                ).format(earnedDate),
                                style: TextStyle(
                                  fontSize: Dimensions.fontBodySmall,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.spacingMedium,
                            vertical: Dimensions.spacingTiny,
                          ),
                          decoration: BoxDecoration(
                            color: reward.isConsumed
                                ? colors.iconGrey.withOpacity(0.1)
                                : colors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusPill,
                            ),
                          ),
                          child: Text(
                            reward.isConsumed
                                ? l10n.rewardConsumed
                                : l10n.useRewardBtn,
                            style: TextStyle(
                              fontSize: Dimensions.fontBodySmall * 0.9,
                              fontWeight: FontWeight.w800,
                              color: reward.isConsumed
                                  ? colors.iconGrey
                                  : colors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
