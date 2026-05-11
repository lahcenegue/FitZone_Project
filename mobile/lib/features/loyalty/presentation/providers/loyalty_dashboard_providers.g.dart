// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loyaltyApiService)
final loyaltyApiServiceProvider = LoyaltyApiServiceProvider._();

final class LoyaltyApiServiceProvider
    extends
        $FunctionalProvider<
          LoyaltyApiService,
          LoyaltyApiService,
          LoyaltyApiService
        >
    with $Provider<LoyaltyApiService> {
  LoyaltyApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyApiServiceHash();

  @$internal
  @override
  $ProviderElement<LoyaltyApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoyaltyApiService create(Ref ref) {
    return loyaltyApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoyaltyApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoyaltyApiService>(value),
    );
  }
}

String _$loyaltyApiServiceHash() => r'e8fe56d2bf91852aac414424db791fc449fc4aa9';

@ProviderFor(loyaltyWallet)
final loyaltyWalletProvider = LoyaltyWalletProvider._();

final class LoyaltyWalletProvider
    extends
        $FunctionalProvider<
          AsyncValue<WalletSummary>,
          WalletSummary,
          FutureOr<WalletSummary>
        >
    with $FutureModifier<WalletSummary>, $FutureProvider<WalletSummary> {
  LoyaltyWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyWalletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyWalletHash();

  @$internal
  @override
  $FutureProviderElement<WalletSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WalletSummary> create(Ref ref) {
    return loyaltyWallet(ref);
  }
}

String _$loyaltyWalletHash() => r'ae41dab6e6adf63074a884cb78ffd3bc3725655b';

@ProviderFor(loyaltyPackages)
final loyaltyPackagesProvider = LoyaltyPackagesProvider._();

final class LoyaltyPackagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoyaltyPackage>>,
          List<LoyaltyPackage>,
          FutureOr<List<LoyaltyPackage>>
        >
    with
        $FutureModifier<List<LoyaltyPackage>>,
        $FutureProvider<List<LoyaltyPackage>> {
  LoyaltyPackagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyPackagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyPackagesHash();

  @$internal
  @override
  $FutureProviderElement<List<LoyaltyPackage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LoyaltyPackage>> create(Ref ref) {
    return loyaltyPackages(ref);
  }
}

String _$loyaltyPackagesHash() => r'4d651eddc4ae1c21363a0544b41a5436fa2a733a';

@ProviderFor(allUserMilestones)
final allUserMilestonesProvider = AllUserMilestonesProvider._();

final class AllUserMilestonesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserMilestone>>,
          List<UserMilestone>,
          FutureOr<List<UserMilestone>>
        >
    with
        $FutureModifier<List<UserMilestone>>,
        $FutureProvider<List<UserMilestone>> {
  AllUserMilestonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allUserMilestonesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allUserMilestonesHash();

  @$internal
  @override
  $FutureProviderElement<List<UserMilestone>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserMilestone>> create(Ref ref) {
    return allUserMilestones(ref);
  }
}

String _$allUserMilestonesHash() => r'2994c655e211d6981cccff40d4e4677cca031f1f';

@ProviderFor(consumedRewards)
final consumedRewardsProvider = ConsumedRewardsProvider._();

final class ConsumedRewardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserMilestone>>,
          List<UserMilestone>,
          FutureOr<List<UserMilestone>>
        >
    with
        $FutureModifier<List<UserMilestone>>,
        $FutureProvider<List<UserMilestone>> {
  ConsumedRewardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consumedRewardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consumedRewardsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserMilestone>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserMilestone>> create(Ref ref) {
    return consumedRewards(ref);
  }
}

String _$consumedRewardsHash() => r'0936eb4a489aff3726d2216285fb13a7b0815f27';

@ProviderFor(dashboardTransactions)
final dashboardTransactionsProvider = DashboardTransactionsProvider._();

final class DashboardTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedTransactions>,
          PaginatedTransactions,
          FutureOr<PaginatedTransactions>
        >
    with
        $FutureModifier<PaginatedTransactions>,
        $FutureProvider<PaginatedTransactions> {
  DashboardTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<PaginatedTransactions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedTransactions> create(Ref ref) {
    return dashboardTransactions(ref);
  }
}

String _$dashboardTransactionsHash() =>
    r'1e7266904864b5a424be2ed9a38b038f7239d8c8';

@ProviderFor(transactionSummary)
final transactionSummaryProvider = TransactionSummaryProvider._();

final class TransactionSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransactionSummary>,
          TransactionSummary,
          FutureOr<TransactionSummary>
        >
    with
        $FutureModifier<TransactionSummary>,
        $FutureProvider<TransactionSummary> {
  TransactionSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionSummaryHash();

  @$internal
  @override
  $FutureProviderElement<TransactionSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TransactionSummary> create(Ref ref) {
    return transactionSummary(ref);
  }
}

String _$transactionSummaryHash() =>
    r'4a58c8b92fd33b81380f56ebdd1225b2cee4bd82';

@ProviderFor(filteredTransactions)
final filteredTransactionsProvider = FilteredTransactionsFamily._();

final class FilteredTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedTransactions>,
          PaginatedTransactions,
          FutureOr<PaginatedTransactions>
        >
    with
        $FutureModifier<PaginatedTransactions>,
        $FutureProvider<PaginatedTransactions> {
  FilteredTransactionsProvider._({
    required FilteredTransactionsFamily super.from,
    required ({int? limit, int? page, String? type}) super.argument,
  }) : super(
         retry: null,
         name: r'filteredTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredTransactionsHash();

  @override
  String toString() {
    return r'filteredTransactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PaginatedTransactions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedTransactions> create(Ref ref) {
    final argument = this.argument as ({int? limit, int? page, String? type});
    return filteredTransactions(
      ref,
      limit: argument.limit,
      page: argument.page,
      type: argument.type,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredTransactionsHash() =>
    r'd3e8b350e42eef8d424c37e77e6117356f94ff88';

final class FilteredTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PaginatedTransactions>,
          ({int? limit, int? page, String? type})
        > {
  FilteredTransactionsFamily._()
    : super(
        retry: null,
        name: r'filteredTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredTransactionsProvider call({int? limit, int? page, String? type}) =>
      FilteredTransactionsProvider._(
        argument: (limit: limit, page: page, type: type),
        from: this,
      );

  @override
  String toString() => r'filteredTransactionsProvider';
}

@ProviderFor(dashboardRewards)
final dashboardRewardsProvider = DashboardRewardsProvider._();

final class DashboardRewardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedUserMilestones>,
          PaginatedUserMilestones,
          FutureOr<PaginatedUserMilestones>
        >
    with
        $FutureModifier<PaginatedUserMilestones>,
        $FutureProvider<PaginatedUserMilestones> {
  DashboardRewardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardRewardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardRewardsHash();

  @$internal
  @override
  $FutureProviderElement<PaginatedUserMilestones> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedUserMilestones> create(Ref ref) {
    return dashboardRewards(ref);
  }
}

String _$dashboardRewardsHash() => r'82fdc4f4bbaa6d4db99d706732a60bacbd75723b';

@ProviderFor(dashboardPoints)
final dashboardPointsProvider = DashboardPointsProvider._();

final class DashboardPointsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaginatedPointsTransactions>,
          PaginatedPointsTransactions,
          FutureOr<PaginatedPointsTransactions>
        >
    with
        $FutureModifier<PaginatedPointsTransactions>,
        $FutureProvider<PaginatedPointsTransactions> {
  DashboardPointsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardPointsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardPointsHash();

  @$internal
  @override
  $FutureProviderElement<PaginatedPointsTransactions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaginatedPointsTransactions> create(Ref ref) {
    return dashboardPoints(ref);
  }
}

String _$dashboardPointsHash() => r'6bbf8afa14e34d64f1ce42d7407bb178289361b9';

@ProviderFor(loyaltyRoadmap)
final loyaltyRoadmapProvider = LoyaltyRoadmapProvider._();

final class LoyaltyRoadmapProvider
    extends
        $FunctionalProvider<
          AsyncValue<LoyaltyRoadmapResponse>,
          LoyaltyRoadmapResponse,
          FutureOr<LoyaltyRoadmapResponse>
        >
    with
        $FutureModifier<LoyaltyRoadmapResponse>,
        $FutureProvider<LoyaltyRoadmapResponse> {
  LoyaltyRoadmapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyRoadmapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyRoadmapHash();

  @$internal
  @override
  $FutureProviderElement<LoyaltyRoadmapResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LoyaltyRoadmapResponse> create(Ref ref) {
    return loyaltyRoadmap(ref);
  }
}

String _$loyaltyRoadmapHash() => r'2390dd26f23b0100dcf6918aefaec21bc10116df';

@ProviderFor(pointsSummary)
final pointsSummaryProvider = PointsSummaryProvider._();

final class PointsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PointsSummary>,
          PointsSummary,
          FutureOr<PointsSummary>
        >
    with $FutureModifier<PointsSummary>, $FutureProvider<PointsSummary> {
  PointsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pointsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pointsSummaryHash();

  @$internal
  @override
  $FutureProviderElement<PointsSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PointsSummary> create(Ref ref) {
    return pointsSummary(ref);
  }
}

String _$pointsSummaryHash() => r'7c59f98a58fa4088d68928370e3bae68fd03465e';

@ProviderFor(rewardsSummary)
final rewardsSummaryProvider = RewardsSummaryProvider._();

final class RewardsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<RewardsSummary>,
          RewardsSummary,
          FutureOr<RewardsSummary>
        >
    with $FutureModifier<RewardsSummary>, $FutureProvider<RewardsSummary> {
  RewardsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rewardsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rewardsSummaryHash();

  @$internal
  @override
  $FutureProviderElement<RewardsSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RewardsSummary> create(Ref ref) {
    return rewardsSummary(ref);
  }
}

String _$rewardsSummaryHash() => r'2e48a8c4ee8e3436f638eafb5a7f0a7f28070d10';
