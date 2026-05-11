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
import '../widgets/premium_history_card.dart';

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
        filter: typeParam,
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

  String _getLocalizedTitle(String backendTitle, AppLocalizations l10n) {
    switch (backendTitle) {
      case 'Subscription Resale Revenue':
        return l10n.subscriptionResaleRevenue;
      case 'Pending Resale Funds':
        return l10n.pendingResaleFunds;
      case 'Bank Withdrawal Request':
        return l10n.bankWithdrawalRequest;
      default:
        return backendTitle;
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'completed':
        return l10n.statusCompleted;
      case 'pending':
        return l10n.statusPending;
      case 'escrow':
        return l10n.statusEscrow;
      case 'failed':
        return l10n.statusFailed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final Map<String, String> filterOptions = {
      'all': l10n.all,
      'income': l10n.deposits,
      'withdrawals': l10n.withdrawals,
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

                      // ARCHITECTURE FIX: Derive one unified color per transaction
                      Color themeColor;
                      IconData iconData;
                      String amountPrefix = '';

                      if (tx.impact == 'in') {
                        amountPrefix = '+';
                        if (tx.status == 'completed') {
                          themeColor = colors.success;
                          iconData = Icons.arrow_downward_rounded;
                        } else {
                          themeColor = colors.iconGrey;
                          iconData = Icons.lock_clock_rounded;
                        }
                      } else {
                        amountPrefix = '-';
                        if (tx.status == 'completed') {
                          themeColor = colors.primary;
                          iconData = Icons.account_balance_wallet_rounded;
                        } else if (tx.status == 'pending') {
                          themeColor = colors.warning;
                          iconData = Icons.hourglass_empty_rounded;
                        } else {
                          themeColor = colors.error;
                          iconData = Icons.error_outline_rounded;
                        }
                      }

                      final DateTime date =
                          DateTime.tryParse(tx.createdAt)?.toLocal() ??
                          DateTime.now();

                      final String cleanDate = DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                        Localizations.localeOf(context).languageCode,
                      ).format(date);

                      final String localizedStatus = _getLocalizedStatus(
                        tx.status,
                        l10n,
                      );
                      final String localizedTitle = _getLocalizedTitle(
                        tx.title,
                        l10n,
                      );

                      String? releaseDateText;
                      if (tx.impact == 'in' &&
                          tx.status == 'escrow' &&
                          tx.expectedReleaseDate != null) {
                        final DateTime releaseDate =
                            DateTime.tryParse(
                              tx.expectedReleaseDate!,
                            )?.toLocal() ??
                            DateTime.now();
                        final String formattedRelease = DateFormat(
                          'MMM dd, yyyy',
                          Localizations.localeOf(context).languageCode,
                        ).format(releaseDate);

                        releaseDateText = '${l10n.unlocksOn} $formattedRelease';
                      }

                      return PremiumHistoryCard(
                        title: localizedTitle,
                        date: cleanDate,
                        statusLabel: localizedStatus,
                        releaseDateText: releaseDateText,
                        amount: '$amountPrefix${tx.amount}',
                        icon: iconData,
                        themeColor: themeColor,
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
        final double safeGrandTotal = summary.grossEarnings > 0
            ? summary.grossEarnings
            : 1.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Row(
            children: [
              StatSummaryCard(
                title: l10n.grossEarnings,
                value:
                    '${summary.grossEarnings.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.account_balance_rounded,
                color: colors.success,
                colors: colors,
                currentValue: summary.grossEarnings,
                totalValue: safeGrandTotal,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.availableFunds,
                value:
                    '${summary.availableFunds.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.check_circle_outline_rounded,
                color: colors.primary,
                colors: colors,
                currentValue: summary.availableFunds,
                totalValue: safeGrandTotal,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.escrowFunds,
                value:
                    '${summary.pendingEscrow.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.lock_clock_rounded,
                color: colors.warning,
                colors: colors,
                currentValue: summary.pendingEscrow,
                totalValue: safeGrandTotal,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.consumedFunds,
                value:
                    '${summary.totalConsumed.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.shopping_bag_outlined,
                color: colors.error,
                colors: colors,
                currentValue: summary.totalConsumed,
                totalValue: safeGrandTotal,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.withdrawnFunds,
                value:
                    '${summary.totalWithdrawn.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.outbox_rounded,
                color: colors.textSecondary,
                colors: colors,
                currentValue: summary.totalWithdrawn,
                totalValue: safeGrandTotal,
              ),
            ],
          ),
        );
      },
    );
  }
}
