import 'package:fitzone/core/routing/app_router.dart';
import 'package:fitzone/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'core/storage/storage_provider.dart';
import 'core/theme/app_theme_provider.dart';
import 'core/l10n/app_locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const FitZoneApp(),
    ),
  );
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) debugPrint('Error: ${record.error}');
    if (record.stackTrace != null)
      debugPrint('Stack Trace: ${record.stackTrace}');
  });
}

class FitZoneApp extends ConsumerWidget {
  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final currentThemeColors = ref.watch(appThemeProvider);
    final currentLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'FitZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: currentThemeColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentThemeColors.primary,
        ),
      ),
      locale: currentLocale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        Dimensions.init(View.of(context));
        return child!;
      },
    );
  }
}
