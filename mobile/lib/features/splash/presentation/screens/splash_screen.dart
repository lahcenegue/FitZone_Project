import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/init/app_init_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/routing/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = ref.watch(appThemeProvider);
    final startupState = ref.watch(appStartupProvider);

    return startupState.when(
      data: (_) {
        // Safe navigation after frame is completely built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(RoutePaths.explore);
        });
        return _buildSplashUI(colors);
      },
      error: (error, stackTrace) {
        // If network fails, proceed with cached data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go(RoutePaths.explore);
        });
        return _buildSplashUI(colors);
      },
      loading: () => _buildSplashUI(colors),
    );
  }

  Widget _buildSplashUI(AppColors colors) {
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 100,
              color: colors.primary,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: colors.primary),
          ],
        ),
      ),
    );
  }
}
