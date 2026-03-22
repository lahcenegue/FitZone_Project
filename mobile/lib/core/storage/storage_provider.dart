import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

part 'storage_provider.g.dart';

/// Provides the initialized SharedPreferences instance.
/// Must be overridden in main.dart before app startup.
@Riverpod(keepAlive: true)
SharedPreferences sharedPrefs(Ref ref) {
  throw UnimplementedError('sharedPrefs must be overridden in main.dart');
}

/// Provides the globally accessible StorageService.
@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  final SharedPreferences prefs = ref.watch(sharedPrefsProvider);
  return StorageService(prefs);
}
