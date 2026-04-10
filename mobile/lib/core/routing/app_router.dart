import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'main_shell_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/explore/presentation/screens/explore_filters_screen.dart';
import '../../features/gyms/presentation/screens/gym_details_screen.dart';

import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:fitzone/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:fitzone/features/auth/presentation/screens/login_screen.dart';
import 'package:fitzone/features/auth/presentation/screens/reset_password_screen.dart';
// استيراد الشاشات الجديدة
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';

import 'package:fitzone/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitzone/features/profile/presentation/screens/personal_info_screen.dart';

import '../l10n/l10n_extension.dart';

class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String filters = '/filters';

  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String explore = '/';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';

  // New Routes added
  static const String changePassword = '/change-password';
  static const String deleteAccount = '/delete-account';

  static const String gymDetails = '/gym/:id';

  static String gymDetailsPath(int id) => '/gym/$id';
}

final Logger _routerLogger = Logger('AppRouter');
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'verify_otp',
        path: RoutePaths.verifyOtp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final String email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: 'reset_password',
        path: RoutePaths.resetPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final String email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.completeProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.personalInfo,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      // --- إضافة مسارات الشاشات الجديدة هنا ---
      GoRoute(
        path: RoutePaths.changePassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.deleteAccount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
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
      GoRoute(
        path: RoutePaths.gymDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final int gymId =
              int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
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
      return Scaffold(body: Center(child: Text('${state.error}')));
    },
  );
});

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(context.l10n.savedItems)));
}
