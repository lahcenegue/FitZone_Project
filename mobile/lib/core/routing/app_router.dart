import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/delete_account_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/explore/presentation/screens/explore_filters_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/gyms/presentation/screens/gym_details_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/loyalty/presentation/screens/bank_account_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_dashboard_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_gamified_track_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_packages_screen.dart';
import '../../features/loyalty/presentation/screens/points_history_screen.dart';
import '../../features/loyalty/presentation/screens/rewards_history_screen.dart';
import '../../features/loyalty/presentation/screens/transactions_history_screen.dart';
import '../../features/loyalty/presentation/screens/withdraw_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_filters_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/personal_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/subscriptions/data/models/subscription_model.dart';
import '../../features/subscriptions/presentation/screens/checkout_screen.dart';
import '../../features/subscriptions/presentation/screens/my_subscriptions_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_details_screen.dart';
import 'main_shell_screen.dart';

class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String filters = '/filters';
  static const String marketplaceFilters =
      '/marketplace-filters'; // ARCHITECTURE FIX: New Route
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String completeProfile = '/complete-profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String home = '/';
  static const String explore = '/explore';
  static const String marketplace = '/marketplace';
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

    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final user = authState.value;

      final bool isSplash = state.uri.path == RoutePaths.splash;
      final bool isAuthRoute = [
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.forgotPassword,
        RoutePaths.resetPassword,
        RoutePaths.verifyOtp,
      ].contains(state.uri.path);

      final bool isPublicRoute =
          [
            RoutePaths.home,
            RoutePaths.explore,
            RoutePaths.marketplace,
            RoutePaths.filters,
            RoutePaths.marketplaceFilters, // Authorized Public Route
            RoutePaths.profile,
          ].contains(state.uri.path) ||
          state.uri.path.startsWith('/gym/');

      if (isSplash) return null;

      if (user == null) {
        if (!isAuthRoute && !isPublicRoute) {
          _routerLogger.warning(
            'Unauthorized access attempt to ${state.uri.path}. Redirecting to Login.',
          );
          return RoutePaths.login;
        }
        return null;
      }

      if (!user.isVerified) {
        if (state.uri.path != RoutePaths.verifyOtp) {
          _routerLogger.warning(
            'User is not verified. Forcing redirect to OTP.',
          );
          return '${RoutePaths.verifyOtp}?email=${user.email}';
        }
        return null;
      }

      if (isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'verify_otp',
        path: RoutePaths.verifyOtp,
        builder: (context, state) {
          final String email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: 'reset_password',
        path: RoutePaths.resetPassword,
        builder: (context, state) {
          final String email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.completeProfile,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.personalInfo,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: RoutePaths.checkout,
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
        builder: (context, state) => const LoyaltyDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.gamifiedTrack,
        builder: (context, state) => const LoyaltyGamifiedTrackScreen(),
      ),
      GoRoute(
        path: RoutePaths.bankAccount,
        builder: (context, state) => const BankAccountScreen(),
      ),
      GoRoute(
        path: RoutePaths.withdraw,
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: RoutePaths.transactionsHistory,
        builder: (context, state) => const TransactionsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.pointsHistory,
        builder: (context, state) => const PointsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.rewardsHistory,
        builder: (context, state) => const RewardsHistoryScreen(),
      ),
      GoRoute(
        path: RoutePaths.buyPoints,
        builder: (context, state) => const LoyaltyPackagesScreen(),
      ),
      GoRoute(
        path: RoutePaths.mySubscriptions,
        builder: (context, state) => const MySubscriptionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.subscriptionDetails,
        builder: (context, state) {
          final sub = state.extra as SubscriptionModel;
          return SubscriptionDetailsScreen(subscription: sub);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.marketplace,
                builder: (context, state) => const MarketplaceScreen(),
              ),
            ],
          ),
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
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Saved Items'))),
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
        builder: (context, state) {
          final int gymId =
              int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return GymDetailsScreen(gymId: gymId);
        },
      ),
      GoRoute(
        path: RoutePaths.filters,
        builder: (context, state) => const ExploreFiltersScreen(),
      ),
      // ARCHITECTURE FIX: Appended Marketplace Filters Route
      GoRoute(
        path: RoutePaths.marketplaceFilters,
        builder: (context, state) => const MarketplaceFiltersScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      _routerLogger.severe('Navigation error: ${state.error}');
      return Scaffold(body: Center(child: Text('${state.error}')));
    },
  );
});
