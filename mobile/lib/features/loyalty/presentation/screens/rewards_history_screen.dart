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
import '../widgets/premium_history_card.dart'; // IMPORTED REUSABLE WIDGET

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
  String _selectedFilter = 'all';

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
      ref.invalidate(rewardsSummaryProvider);
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
        child: RefreshIndicator(
          color: colors.primary,
          backgroundColor: colors.surface,
          onRefresh: () => _fetchRewards(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.spacingMedium),
              ),
              SliverToBoxAdapter(child: _buildSummaryCards(colors, l10n)),
              SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.spacingLarge),
              ),
              SliverToBoxAdapter(
                child: DynamicFilterRow(
                  filters: filterOptions,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: _onFilterChanged,
                  colors: colors,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.spacingMedium),
              ),

              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                )
              else if (_rewards.isEmpty)
                SliverFillRemaining(
                  child: CustomEmptyState(
                    message: l10n.noRewards,
                    icon: Icons.card_giftcard_rounded,
                    colors: colors,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingLarge,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == _rewards.length) {
                        return Padding(
                          padding: EdgeInsets.all(Dimensions.spacingLarge),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          ),
                        );
                      }

                      final reward = _rewards[index];
                      final String dateString =
                          reward.claimedAt ?? reward.unlockedAt;
                      final DateTime earnedDate =
                          DateTime.tryParse(dateString)?.toLocal() ??
                          DateTime.now();
                      final String formattedDate = DateFormat(
                        'MMM dd, yyyy',
                        Localizations.localeOf(context).languageCode,
                      ).format(earnedDate);

                      final Color statusColor = reward.isConsumed
                          ? colors.iconGrey
                          : colors.success;
                      final String statusText = reward.isConsumed
                          ? l10n.rewardConsumed
                          : l10n.rewardAvailable;
                      final IconData icon = reward.isConsumed
                          ? Icons.check_circle_rounded
                          : Icons.card_giftcard_rounded;

                      // ARCHITECTURE FIX: Using the DRY PremiumHistoryCard
                      return PremiumHistoryCard(
                        title:
                            reward.milestone.reward?.name ??
                            reward.milestone.title,
                        subtitle: formattedDate,
                        trailingText: statusText,
                        icon: icon,
                        color: statusColor,
                        colors: colors,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => LoyaltyRewardSheet(
                              userMilestone: reward,
                              colors: colors,
                              l10n: l10n,
                            ),
                          );
                        },
                      );
                    }, childCount: _rewards.length + (_hasMore ? 1 : 0)),
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(height: Dimensions.spacingExtraLarge),
              ),
            ],
          ),
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
        final double totalOverall =
            (summary.totalAvailable + summary.totalConsumed).toDouble();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Row(
            children: [
              Expanded(
                child: StatSummaryCard(
                  title: l10n.rewardAvailable,
                  value: summary.totalAvailable.toString(),
                  icon: Icons.redeem_rounded,
                  color: colors.success,
                  colors: colors,
                  currentValue: summary.totalAvailable.toDouble(),
                  totalValue: totalOverall,
                ),
              ),
              SizedBox(width: Dimensions.spacingMedium),
              Expanded(
                child: StatSummaryCard(
                  title: l10n.rewardConsumed,
                  value: summary.totalConsumed.toString(),
                  icon: Icons.check_circle_rounded,
                  color: colors.iconGrey,
                  colors: colors,
                  currentValue: summary.totalConsumed.toDouble(),
                  totalValue: totalOverall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
