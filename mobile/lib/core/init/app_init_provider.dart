import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import '../config/api_constants.dart';
import '../network/api_provider.dart';
import '../storage/storage_provider.dart';
import '../storage/storage_service.dart';

part 'app_init_provider.g.dart';

/// Service responsible for bootstrapping the app and synchronizing static data.
class AppInitService {
  final Dio _dio;
  final StorageService _storage;
  final Logger _logger = Logger('AppInitService');

  AppInitService(this._dio, this._storage);

  /// Checks for metadata updates and fetches new data if versions differ.
  Future<void> initializeApp() async {
    try {
      _logger.info('Starting app initialization sequence...');

      final Response initResponse = await _dio.get(ApiConstants.initConfig);
      final Map<String, dynamic> initData =
          initResponse.data as Map<String, dynamic>;

      final double remoteSportsVersion =
          (initData['sports_version'] as num?)?.toDouble() ?? 0.0;
      final double remoteAmenitiesVersion =
          (initData['amenities_version'] as num?)?.toDouble() ?? 0.0;
      final double remoteCitiesVersion =
          (initData['cities_version'] as num?)?.toDouble() ?? 0.0;

      // 1. Sync Sports
      if (remoteSportsVersion > _storage.sportsVersion) {
        _logger.info('Updating sports data from API...');
        await _fetchAndCache(ApiConstants.sports, (data) async {
          await _storage.setSportsData(data);
          await _storage.setSportsVersion(remoteSportsVersion);
        });
      }

      // 2. Sync Amenities
      if (remoteAmenitiesVersion > _storage.amenitiesVersion) {
        _logger.info('Updating amenities data from API...');
        await _fetchAndCache(ApiConstants.amenities, (data) async {
          await _storage.setAmenitiesData(data);
          await _storage.setAmenitiesVersion(remoteAmenitiesVersion);
        });
      }

      // 3. Sync Cities
      if (remoteCitiesVersion > _storage.citiesVersion) {
        _logger.info('Updating cities data from API...');
        await _fetchAndCache(ApiConstants.cities, (data) async {
          await _storage.setCitiesData(data);
          await _storage.setCitiesVersion(remoteCitiesVersion);
        });
      }

      _logger.info('App initialization complete. All data is up to date.');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to initialize app data. Relying on cache.',
        e,
        stackTrace,
      );
      // We do not throw the error to allow the app to start offline using cached data.
    }
  }

  /// Helper method to fetch data and pass it to the appropriate save callback.
  Future<void> _fetchAndCache(
    String endpoint,
    Future<void> Function(List<dynamic>) onSave,
  ) async {
    final Response response = await _dio.get(endpoint);
    final List<dynamic> data = response.data as List<dynamic>;
    await onSave(data);
  }
}

/// Provides the AppInitService instance.
@Riverpod(keepAlive: true)
AppInitService appInitService(Ref ref) {
  final Dio dio = ref.watch(dioClientProvider);
  final StorageService storage = ref.watch(storageServiceProvider);
  return AppInitService(dio, storage);
}
