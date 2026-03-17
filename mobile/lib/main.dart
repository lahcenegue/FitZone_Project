import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routing/app_router.dart';
import 'core/theme/dimensions.dart';
import 'l10n/app_localizations.dart';

/// Entry point of the FitZone application.
void main() {
  _setupLogging();

  runApp(const ProviderScope(child: FitZoneApp()));
}

/// Configures the logging framework for the application.
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack Trace: ${record.stackTrace}');
    }
  });
}

/// The root widget of the application.
class FitZoneApp extends ConsumerWidget {
  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'FitZone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: const Locale('en'),
      routerConfig: router,
      builder: (context, child) {
        // Initialize Dimensions here before any screen is rendered.
        // View.of(context) gets the physical dimensions of the current display.
        Dimensions.init(View.of(context));
        return child!;
      },
    );
  }
}
