import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
import '../../data/models/resale_models.dart';
import '../../data/services/marketplace_api_service.dart';

part 'marketplace_providers.g.dart';

@Riverpod(keepAlive: true)
MarketplaceApiService marketplaceApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return MarketplaceApiService(dio: dio);
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
    return _fetchPage(1);
  }

  Future<MarketplaceState> _fetchPage(int page) async {
    final service = ref.read(marketplaceApiServiceProvider);
    final response = await service.discoverResaleItems(page: page);

    return MarketplaceState(
      items: response.results,
      page: response.currentPage,
      hasNext: response.hasNext,
      isLoadMore: false,
    );
  }

  Future<void> loadMore() async {
    // ARCHITECTURE FIX: Replaced valueOrNull with value
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasNext ||
        currentState.isLoadMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadMore: true));

    try {
      final service = ref.read(marketplaceApiServiceProvider);
      final response = await service.discoverResaleItems(
        page: currentState.page + 1,
      );

      state = AsyncData(
        currentState.copyWith(
          items: [...currentState.items, ...response.results],
          page: response.currentPage,
          hasNext: response.hasNext,
          isLoadMore: false,
        ),
      );
    } catch (e, stackTrace) {
      // ARCHITECTURE FIX: Utilized stackTrace properly via Logger
      _logger.severe('Failed to load more marketplace items', e, stackTrace);
      state = AsyncData(currentState.copyWith(isLoadMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }
}
