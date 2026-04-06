import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../config/api_constants.dart';
import '../network/api_provider.dart';
import '../database/database_service.dart';
import '../location/location_provider.dart';

part 'app_init_provider.g.dart';

class OfflineException implements Exception {}

class LocationDisabledException implements Exception {}

enum StartupStatus { success, locationTimeout }

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

@Riverpod(keepAlive: true)
Future<StartupStatus> appStartup(Ref ref) async {
  final Logger logger = Logger('AppStartup');

  logger.info('Phase 1: Checking Hardware Network State...');
  final List<ConnectivityResult> connectivityResult = await Connectivity()
      .checkConnectivity();
  if (connectivityResult.contains(ConnectivityResult.none)) {
    throw OfflineException();
  }

  logger.info('Phase 2: Verifying Real Internet Access...');
  bool hasInternet = false;
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 3));
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      hasInternet = true;
    }
  } catch (_) {
    hasInternet = false;
  }

  if (!hasInternet) {
    logger.warning('Real Internet check failed or timed out.');
    throw OfflineException();
  }

  logger.info('Phase 3: Checking Location Services...');
  final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw LocationDisabledException();
  }

  logger.info(
    'Phase 4: Parallel Execution (Waiting for GPS Lock & DB Sync)...',
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
        .timeout(const Duration(seconds: 15));
    logger.info('GPS Lock acquired successfully.');
    return false;
  } catch (e) {
    logger.warning(
      'GPS Lock timed out after 15 seconds. Proceeding to explore screen.',
    );
    return true;
  }
}
