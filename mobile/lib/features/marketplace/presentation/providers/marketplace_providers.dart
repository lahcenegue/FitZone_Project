import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/models/resale_models.dart';
import '../../data/services/marketplace_api_service.dart';
import 'marketplace_filter_state.dart';

part 'marketplace_providers.g.dart';

@Riverpod(keepAlive: true)
MarketplaceApiService marketplaceApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return MarketplaceApiService(dio: dio);
}

@riverpod
class MarketplaceFilter extends _$MarketplaceFilter {
  @override
  MarketplaceFilterState build() {
    return const MarketplaceFilterState();
  }

  void updateFilters(MarketplaceFilterState newState) {
    state = newState;
  }

  void resetFilters() {
    state = const MarketplaceFilterState();
  }
}

class MarketplaceState {
  final List<ResaleItem> items;
  final int page;
  final bool hasNext;
  final bool isLoadMore;

  MarketplaceState({
    this.items = const [],
    this.page = 1,
    this.hasNext = false,
    this.isLoadMore = false,
  });

  MarketplaceState copyWith({
    List<ResaleItem>? items,
    int? page,
    bool? hasNext,
    bool? isLoadMore,
  }) {
    return MarketplaceState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoadMore: isLoadMore ?? this.isLoadMore,
    );
  }
}

@riverpod
class MarketplaceController extends _$MarketplaceController {
  final Logger _logger = Logger('MarketplaceController');

  @override
  FutureOr<MarketplaceState> build() async {
    ref.watch(marketplaceFilterProvider);
    ref.watch(userLocationProvider);

    return _fetchPage(1);
  }

  Future<MarketplaceState> _fetchPage(int page) async {
    final service = ref.read(marketplaceApiServiceProvider);
    final filters = ref.read(marketplaceFilterProvider);

    final locationState = ref.read(userLocationProvider);
    final userLocation = locationState.location;

    final response = await service.discoverResaleItems(
      page: page,
      q: filters.query,
      city: filters.cityId,
      gender: filters.gender,
      minPrice: filters.minPrice,
      maxPrice: filters.maxPrice,
      minDays: filters.minDays,
      minDiscount: filters.minDiscount,
      radiusKm: filters.radiusKm,
      sortBy: filters.sortBy,
      userLat: userLocation?.latitude,
      userLng: userLocation?.longitude,
    );

    // ARCHITECTURE FIX: Enforce ID deduplication to prevent double rendering
    final uniqueItems = <int, ResaleItem>{};
    for (var item in response.results) {
      uniqueItems[item.id] = item;
    }

    return MarketplaceState(
      items: uniqueItems.values.toList(),
      page: response.currentPage,
      hasNext: response.hasNext,
      isLoadMore: false,
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasNext ||
        currentState.isLoadMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadMore: true));

    try {
      final nextPageItems = await _fetchPage(currentState.page + 1);

      // ARCHITECTURE FIX: Strict deduplication when merging new pages
      final existingIds = currentState.items.map((e) => e.id).toSet();
      final newUniqueItems = nextPageItems.items
          .where((e) => !existingIds.contains(e.id))
          .toList();

      state = AsyncData(
        currentState.copyWith(
          items: [...currentState.items, ...newUniqueItems],
          page: nextPageItems.page,
          hasNext: nextPageItems.hasNext,
          isLoadMore: false,
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to load more marketplace items', e, stackTrace);
      state = AsyncData(currentState.copyWith(isLoadMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }
}
