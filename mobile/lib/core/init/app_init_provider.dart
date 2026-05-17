import 'dart:async';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../config/api_constants.dart';
import '../config/app_constants.dart';
import '../network/api_provider.dart';
import '../database/database_service.dart';
import '../location/location_provider.dart';
import '../storage/storage_provider.dart';
import '../storage/storage_service.dart';

part 'app_init_provider.g.dart';

class OfflineException implements Exception {}

class LocationDisabledException implements Exception {}

enum StartupStatus { success, locationTimeout }

class AppInitService {
  final Dio _dio;
  final DatabaseService _dbService;
  final StorageService _storageService;
  final Logger _logger = Logger('AppInitService');

  AppInitService({
    required Dio dio,
    required DatabaseService dbService,
    required StorageService storageService,
  }) : _dio = dio,
       _dbService = dbService,
       _storageService = storageService;

  Future<void> initializeApp() async {
    try {
      final double localRoadmapVersion = await _dbService.getVersion(
        'loyalty_roadmap_version',
      );
      final bool isFirstLaunch = localRoadmapVersion == 0.0;

      if (isFirstLaunch) {
        _logger.info(
          'First app launch detected. Blocking UI to fetch baseline configs.',
        );
        await _fetchAndSyncInit();
      } else {
        _logger.info(
          'Returning user. Bypassing /init/ wait to unblock UI. Triggering in background.',
        );
        unawaited(_fetchAndSyncInit());
      }
    } catch (e, stackTrace) {
      _logger.severe(
        'Initialization process failed. Relying on cached data.',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _fetchAndSyncInit() async {
    try {
      final Response initResponse = await _dio.get(
        ApiConstants.initConfig,
        // ARCHITECTURE FIX: Using centralized constant
        options: Options(
          receiveTimeout: const Duration(
            seconds: AppConstants.apiTimeoutSeconds,
          ),
        ),
      );
      final Map<String, dynamic> initData =
          initResponse.data as Map<String, dynamic>;

      // ARCHITECTURE FIX: Using centralized constant
      final int premiumPoints =
          initData['premium_points_required'] as int? ??
          AppConstants.defaultPremiumPoints;
      await _storageService.setPremiumPointsRequired(premiumPoints);

      final double roadmapVersion =
          (initData['loyalty_roadmap_version'] as num?)?.toDouble() ?? 0.0;
      await _dbService.setVersion('loyalty_roadmap_version', roadmapVersion);

      _logger.info(
        'Spawning background task for heavy SQLite synchronizations...',
      );
      unawaited(_runBackgroundSync(initData));
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch /init/ configs', e, stackTrace);
    }
  }

  Future<void> _runBackgroundSync(Map<String, dynamic> initData) async {
    _logger.info('Background Sync Started: Verifying versions...');
    try {
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

      _logger.info('Background Sync Completed successfully.');
    } catch (e, stackTrace) {
      _logger.severe('Background Sync Encountered an Error.', e, stackTrace);
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
        'Background Update: $versionKey from $localVersion to $remoteVersion...',
      );
      final Response response = await _dio.get(endpoint);
      final List<dynamic> data = response.data as List<dynamic>;

      await insertOperation(data);
      await _dbService.setVersion(versionKey, remoteVersion);
    } else {
      _logger.info(
        'Background Check: $versionKey is up to date ($localVersion).',
      );
    }
  }
}

@Riverpod(keepAlive: true)
AppInitService appInitService(Ref ref) {
  final Dio dio = ref.watch(dioClientProvider);
  final DatabaseService dbService = ref.watch(databaseServiceProvider);
  final StorageService storageService = ref.watch(storageServiceProvider);

  return AppInitService(
    dio: dio,
    dbService: dbService,
    storageService: storageService,
  );
}

@Riverpod(keepAlive: true)
Future<StartupStatus> appStartup(Ref ref) async {
  final Logger logger = Logger('AppStartup');

  logger.info('Phase 1: Checking Hardware Network State...');
  final List<ConnectivityResult> connectivityResult = await Connectivity()
      .checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    throw OfflineException();
  }

  logger.info(
    'Phase 2: Verifying Real Internet Access via Hyper-Fast Checker...',
  );
  final bool hasInternet = await InternetConnection().hasInternetAccess;
  if (!hasInternet) {
    logger.warning('Real Internet check failed.');
    throw OfflineException();
  }

  logger.info('Phase 3: Checking Location Services...');
  final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw LocationDisabledException();
  }

  logger.info(
    'Phase 4: Parallel Execution (Waiting for GPS Lock & Init Config)...',
  );
  bool locationTimedOut = false;

  await Future.wait([
    ref.read(appInitServiceProvider).initializeApp(),
    _fetchLocationWithTimeout(ref, logger).then((timedOut) {
      locationTimedOut = timedOut;
    }),
  ]);

  return locationTimedOut
      ? StartupStatus.locationTimeout
      : StartupStatus.success;
}

Future<bool> _fetchLocationWithTimeout(Ref ref, Logger logger) async {
  try {
    await ref
        .read(userLocationProvider.notifier)
        .fetchLocation()
        // ARCHITECTURE FIX: Using centralized constant
        .timeout(const Duration(seconds: AppConstants.locationTimeoutSeconds));
    logger.info('GPS logic resolved successfully.');
    return false;
  } catch (e) {
    logger.warning('GPS logic timed out. Proceeding to explore screen.');
    return true;
  }
}
