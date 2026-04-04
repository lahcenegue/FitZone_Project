import 'package:fitzone/features/explore/presentation/screens/explore_filters_screen.dart';
import 'package:fitzone/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

// Shell & Layout
import 'package:fitzone/core/routing/main_shell_screen.dart';

// Features
import 'package:fitzone/features/explore/presentation/screens/explore_screen.dart';
import 'package:fitzone/features/gyms/presentation/screens/gym_details_screen.dart';

// Localization
import 'package:fitzone/core/l10n/l10n_extension.dart';

/// Defines all strongly-typed route paths used in the application.
class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';

  static const String filters = '/filters';

  // Bottom Navigation Routes
  static const String explore = '/';
  static const String saved = '/saved';
  static const String profile = '/profile';

  // Detail Routes (Top Level)
  static const String gymDetails = '/gym/:id';

  /// Helper method to generate the dynamic gym details path safely
  static String gymDetailsPath(int id) => '/gym/$id';
}

final Logger _routerLogger = Logger('AppRouter');

// Root navigator key is used to push screens OVER the bottom navigation bar
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen Route (Full Screen)
      GoRoute(
        path: RoutePaths.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),

      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.explore,
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Top-level route for Gym Details (Covers the bottom navigation bar)
      GoRoute(
        path: RoutePaths.gymDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final String? idString = state.pathParameters['id'];
          final int gymId = int.tryParse(idString ?? '0') ?? 0;
          return GymDetailsScreen(gymId: gymId);
        },
      ),

      GoRoute(
        path: RoutePaths.filters,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExploreFiltersScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      _routerLogger.severe('Navigation error: ${state.error}');
      return Scaffold(
        body: Center(
          child: Builder(
            builder: (innerContext) {
              return Text(
                '${innerContext.l10n.navigationError}: ${state.error}',
              );
            },
          ),
        ),
      );
    },
  );
});

// --- Mock Screens (To be moved to their respective feature folders later) ---

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.l10n.savedItems)));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.l10n.userProfile)));
  }
}
