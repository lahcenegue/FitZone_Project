import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import '../config/api_constants.dart';
import '../network/api_provider.dart';
import '../database/database_service.dart';
import '../location/location_provider.dart';

part 'app_init_provider.g.dart';

class AppInitService {
  final Dio _dio;
  final DatabaseService _dbService;
  final Logger _logger = Logger('AppInitService');

  AppInitService({required Dio dio, required DatabaseService dbService})
    : _dio = dio,
      _dbService = dbService;

  Future<void> initializeApp() async {
    try {
      _logger.info('Starting app initialization (SQLite Sync)...');

      final Response initResponse = await _dio.get(ApiConstants.initConfig);
      final Map<String, dynamic> initData =
          initResponse.data as Map<String, dynamic>;

      await _syncTable(
        versionKey: 'service_types_version',
        remoteVersion:
            (initData['service_types_version'] as num?)?.toDouble() ?? 0.0,
        endpoint: ApiConstants.serviceTypes,
        insertOperation: _dbService.insertServiceTypes,
      );

      await _syncTable(
        versionKey: 'cities_version',
        remoteVersion: (initData['cities_version'] as num?)?.toDouble() ?? 0.0,
        endpoint: ApiConstants.cities,
        insertOperation: _dbService.insertCities,
      );

      await _syncTable(
        versionKey: 'sports_version',
        remoteVersion: (initData['sports_version'] as num?)?.toDouble() ?? 0.0,
        endpoint: ApiConstants.sports,
        insertOperation: _dbService.insertSports,
      );

      await _syncTable(
        versionKey: 'amenities_version',
        remoteVersion:
            (initData['amenities_version'] as num?)?.toDouble() ?? 0.0,
        endpoint: ApiConstants.amenities,
        insertOperation: _dbService.insertAmenities,
      );

      _logger.info(
        'App initialization complete. SQLite database is up to date.',
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Initialization failed. Relying on cached SQLite data.',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _syncTable({
    required String versionKey,
    required double remoteVersion,
    required String endpoint,
    required Future<void> Function(List<dynamic>) insertOperation,
  }) async {
    final double localVersion = await _dbService.getVersion(versionKey);

    if (remoteVersion > localVersion) {
      _logger.info(
        'Updating $versionKey from $localVersion to $remoteVersion...',
      );
      final Response response = await _dio.get(endpoint);
      final List<dynamic> data = response.data as List<dynamic>;

      await insertOperation(data);
      await _dbService.setVersion(versionKey, remoteVersion);
    } else {
      _logger.info('$versionKey is up to date ($localVersion).');
    }
  }
}

@Riverpod(keepAlive: true)
AppInitService appInitService(Ref ref) {
  final Dio dio = ref.watch(dioClientProvider);
  final DatabaseService dbService = ref.watch(databaseServiceProvider);
  return AppInitService(dio: dio, dbService: dbService);
}

/// The master provider that Bootstraps the entire app
@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  final Logger logger = Logger('AppStartup');

  logger.info('Phase 1: Fetching User Location securely...');
  try {
    // 5 seconds timeout to prevent Splash Screen from freezing if GPS is weak
    await ref
        .read(userLocationProvider.notifier)
        .fetchLocation()
        .timeout(const Duration(seconds: 5));
    logger.info('User location cached successfully.');
  } catch (e) {
    logger.warning(
      'Location fetch timed out or failed. Proceeding to Phase 2...',
    );
  }

  logger.info('Phase 2: Synchronizing Database...');
  final AppInitService initService = ref.read(appInitServiceProvider);
  await initService.initializeApp();
}
