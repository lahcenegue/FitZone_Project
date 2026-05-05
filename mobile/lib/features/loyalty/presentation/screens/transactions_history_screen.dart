import 'package:fitzone/core/presentation/widgets/custom_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/loyalty_models.dart';
import '../providers/loyalty_dashboard_providers.dart';
import '../widgets/dynamic_filter_row.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/transaction_item_card.dart';

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

  // Pagination Constants
  static const int _itemsPerPage = 15;

  // State Variables
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
        backgroundColor: colors.background,
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
                  : _transactions.isEmpty
                  ? CustomEmptyState(
                      message: l10n.noTransactions,
                      icon: Icons.receipt_long_rounded,
                      colors: colors,
                    )
                  : _buildTransactionsList(colors, l10n),
            ),
          ],
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
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.totalSpent,
                value: '${summary.totalSpent.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.arrow_upward_rounded,
                color: colors.error,
                colors: colors,
              ),
              SizedBox(width: Dimensions.spacingMedium),
              StatSummaryCard(
                title: l10n.pendingWithdrawals,
                value:
                    '${summary.pendingWithdrawals.toStringAsFixed(0)} ${l10n.sar}',
                icon: Icons.hourglass_empty_rounded,
                color: colors.warning,
                colors: colors,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(AppColors colors, AppLocalizations l10n) {
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
            itemCount: _transactions.length + (_hasMore ? 1 : 0),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colors.iconGrey.withOpacity(0.1),
              indent: Dimensions.spacingExtraLarge * 2,
            ),
            itemBuilder: (context, index) {
              if (index == _transactions.length) {
                return Padding(
                  padding: EdgeInsets.all(Dimensions.spacingLarge),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                );
              }

              return TransactionItemCard(
                transaction: _transactions[index],
                colors: colors,
                l10n: l10n,
              );
            },
          ),
        ),
      ),
    );
  }
}
