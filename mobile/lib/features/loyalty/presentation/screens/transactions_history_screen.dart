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
import '../widgets/premium_history_card.dart'; // IMPORTED REUSABLE WIDGET

class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState
    extends ConsumerState<TransactionsHistoryScreen> {
  final Logger _logger = Logger('TransactionsHistoryScreen');
  final ScrollController _scrollController = ScrollController();

  static const int _itemsPerPage = 15;

  final List<FinancialTransaction> _transactions = [];
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
      _fetchTransactions(refresh: true);
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
        _fetchTransactions();
      }
    }
  }

  Future<void> _fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
        _transactions.clear();
      });
      ref.invalidate(transactionSummaryProvider);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final apiService = ref.read(loyaltyApiServiceProvider);
      final typeParam = _selectedFilter == 'all' ? null : _selectedFilter;

      final response = await apiService.getTransactions(
        limit: _itemsPerPage,
        page: _page,
        type: typeParam,
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(response.results);
          _hasMore = response.next != null;
          if (_hasMore) _page++;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch transactions', e, stackTrace);
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
    _fetchTransactions(refresh: true);
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
      'deposit': l10n.deposits,
      'withdrawal': l10n.withdrawals,
      'refund': l10n.refunds,
    };

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.transactionsHistory,
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
          onRefresh: () => _fetchTransactions(refresh: true),
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
              else if (_transactions.isEmpty)
                SliverFillRemaining(
                  child: CustomEmptyState(
                    message: l10n.noTransactions,
                    icon: Icons.receipt_long_rounded,
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
                      if (index == _transactions.length) {
                        return Padding(
                          padding: EdgeInsets.all(Dimensions.spacingLarge),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
                          ),
                        );
                      }

                      final tx = _transactions[index];
                      final bool isDeposit =
                          tx.type == 'deposit' || tx.type == 'refund';
                      final bool isPending = tx.status == 'pending';
                      final bool isFailed = tx.status == 'failed';

                      Color badgeColor;
                      IconData iconData;

                      if (isPending) {
                        badgeColor = colors.warning;
                        iconData = Icons.hourglass_empty_rounded;
                      } else if (isFailed) {
                        badgeColor = colors.error;
                        iconData = Icons.error_outline_rounded;
                      } else if (isDeposit) {
                        badgeColor = colors.success;
                        iconData = Icons.arrow_downward_rounded;
                      } else {
                        badgeColor = colors.error;
                        iconData = Icons.arrow_upward_rounded;
                      }

                      final DateTime date =
                          DateTime.tryParse(tx.createdAt)?.toLocal() ??
                          DateTime.now();
                      final String formattedDate = DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                        Localizations.localeOf(context).languageCode,
                      ).format(date);

                      // ARCHITECTURE FIX: Using the DRY PremiumHistoryCard
                      return PremiumHistoryCard(
                        title: tx.title,
                        subtitle: formattedDate,
                        trailingText: '${tx.amount} ${l10n.currency}',
                        icon: iconData,
                        color: badgeColor,
                        colors: colors,
                      );
                    }, childCount: _transactions.length + (_hasMore ? 1 : 0)),
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
    final summaryAsync = ref.watch(transactionSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        final double totalTransactions =
            summary.totalEarned + summary.totalSpent;
        final double safeTotalTransactions = totalTransactions > 0
            ? totalTransactions
            : 1.0;

        final double totalWithdrawals =
            summary.pendingWithdrawals + summary.completedWithdrawals;
        final double safeTotalWithdrawals = totalWithdrawals > 0
            ? totalWithdrawals
            : 1.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Row(
            children: [
              StatSummaryCard(
                title: l10n.totalEarned,
                value: '${summary.totalEarned.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.arrow_downward_rounded,
                color: colors.success,
                colors: colors,
                currentValue: summary.totalEarned,
                totalValue: safeTotalTransactions,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.totalSpent,
                value: '${summary.totalSpent.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.arrow_upward_rounded,
                color: colors.error,
                colors: colors,
                currentValue: summary.totalSpent,
                totalValue: safeTotalTransactions,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.pendingWithdrawals,
                value:
                    '${summary.pendingWithdrawals.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.hourglass_empty_rounded,
                color: colors.warning,
                colors: colors,
                currentValue: summary.pendingWithdrawals,
                totalValue: safeTotalWithdrawals,
              ),
            ],
          ),
        );
      },
    );
  }
}
