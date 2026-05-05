import 'package:fitzone/features/loyalty/presentation/screens/bank_account_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/loyalty_dashboard_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/loyalty_gamified_track_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/loyalty_packages_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/points_history_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/rewards_history_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/transactions_history_screen.dart';
import 'package:fitzone/features/loyalty/presentation/screens/withdraw_screen.dart';

import 'package:fitzone/features/subscriptions/data/models/subscription_model.dart';
import 'package:fitzone/features/subscriptions/presentation/screens/subscription_details_screen.dart';
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

import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';

import 'package:fitzone/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitzone/features/profile/presentation/screens/personal_info_screen.dart';

import '../../features/subscriptions/presentation/screens/checkout_screen.dart';
import '../../features/subscriptions/presentation/screens/my_subscriptions_screen.dart';

import '../l10n/l10n_extension.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

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

  static const String loyalty = '/loyalty';
  static const String gamifiedTrack = '/gamified-track';

  static const String bankAccount = '/bank-account';
  static const String withdraw = '/withdraw';
  static const String buyPoints = '/buy-points';

  static const String transactionsHistory = '/transactions-history';
  static const String pointsHistory = '/points-history';
  static const String rewardsHistory = '/rewards-history';

  static const String changePassword = '/change-password';
  static const String deleteAccount = '/delete-account';

  static const String gymDetails = '/gym/:id';

  static const String checkout = '/checkout';
  static const String mySubscriptions = '/my-subscriptions';
  static const String subscriptionDetails = '/subscription-details';

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

    // ARCHITECTURE FIX: Pure Guard Logic. Prevents unauthorized access but doesn't override manual navigation.
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      final isSplash = state.uri.path == RoutePaths.splash;
      final isAuthRoute =
          state.uri.path == RoutePaths.login ||
          state.uri.path == RoutePaths.register ||
          state.uri.path == RoutePaths.forgotPassword ||
          state.uri.path == RoutePaths.resetPassword ||
          state.uri.path == RoutePaths.verifyOtp;

      final isPublicRoute =
          state.uri.path == RoutePaths.explore ||
          state.uri.path.startsWith('/gym/') ||
          state.uri.path == RoutePaths.filters ||
          state.uri.path == RoutePaths.profile;

      final isLoggedIn = authState.value != null;

      if (isSplash) return null;

      if (!isLoggedIn) {
        if (!isAuthRoute && !isPublicRoute) {
          _routerLogger.warning(
            'Unauthorized access attempt to ${state.uri.path}. Redirecting to Login.',
          );
          return RoutePaths.login;
        }
      } else {
        if (isAuthRoute) {
          // If a logged-in user tries to visit the login screen, kick them out to explore
          return RoutePaths.explore;
        }
      }

      return null; // All good, proceed to intended route
    },

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
      GoRoute(
        path: RoutePaths.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CheckoutScreen(
            planId: extra['planId'] ?? 0,
            planName: extra['planName'] ?? '',
            price: extra['price'] ?? 0.0,
            rewardPoints: extra['rewardPoints'] ?? 0,
            gymName: extra['gymName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.loyalty,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoyaltyDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.gamifiedTrack,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoyaltyGamifiedTrackScreen(),
      ),
      GoRoute(
        path: RoutePaths.bankAccount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BankAccountScreen(),
      ),
      GoRoute(
        path: RoutePaths.withdraw,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WithdrawScreen(),
      ),

      GoRoute(
        path: RoutePaths.transactionsHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TransactionsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.pointsHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PointsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.rewardsHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RewardsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.buyPoints,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoyaltyPackagesScreen(),
      ),
      GoRoute(
        path: RoutePaths.mySubscriptions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MySubscriptionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.subscriptionDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sub = state.extra as SubscriptionModel;
          return SubscriptionDetailsScreen(subscription: sub);
        },
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
