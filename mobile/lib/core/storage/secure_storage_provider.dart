import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secure_storage_service.dart';

part 'secure_storage_provider.g.dart';

/// Provides the initialized FlutterSecureStorage instance.
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

/// Provides the globally accessible SecureStorageService.
@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  final FlutterSecureStorage storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
}
