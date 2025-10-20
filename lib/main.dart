import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/main_navigation.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/pin_setup_screen.dart';
import 'features/auth/presentation/screens/pin_entry_screen.dart';
import 'features/auth/presentation/providers/pin_verification_provider.dart';
import 'features/auth/presentation/providers/app_lifecycle_provider.dart';
import 'features/auth/domain/models/auth_state.dart';

void main() async {
  final stopwatch = Stopwatch()..start();

  // Initialize app configuration
  await AppConfig.initialize();

  // Ensure minimum splash time for smooth UX (prevents flash)
  final elapsed = stopwatch.elapsedMilliseconds;
  if (elapsed < 500) {
    await Future.delayed(Duration(milliseconds: 500 - elapsed));
  }
  stopwatch.stop();
  print('⏱️  Total startup time: ${stopwatch.elapsedMilliseconds}ms');

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);

    // Watch auth state
    final authState = ref.watch(authProvider);

    // Initialize lifecycle provider to start observing app lifecycle
    ref.watch(appLifecycleProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Add global builder to dismiss keyboard on tap outside
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },

      // Home screen based on auth state
      home: _getHomeScreen(authState),
    );
  }

  Widget _getHomeScreen(AuthState authState) {
    return switch (authState) {
      AuthInitial() || AuthLoading() => const SplashScreen(),
      Authenticated() => const AuthenticatedRouter(),
      SessionExpired(:final userId?) => const PinEntryScreen(), // Has PIN, show unlock screen
      Unauthenticated() || AuthError() || SessionExpired() => const LoginScreen(), // No PIN, show login
    };
  }
}

/// Router for authenticated users - decides between PIN setup and home
class AuthenticatedRouter extends ConsumerWidget {
  const AuthenticatedRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isPinVerified = ref.watch(pinVerificationProvider);

    // Reset PIN verification when auth state changes to unauthenticated
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Unauthenticated) {
        ref.read(pinVerificationProvider.notifier).reset();
      }
    });

    if (authState is! Authenticated) {
      return const SplashScreen();
    }

    final user = authState.user;

    if (!user.hasPin) {
      return const PinSetupScreen();
    }

    if (!isPinVerified) {
      return const PinEntryScreen();
    }

    return const MainNavigation();
  }
}

/// Splash screen shown during initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo placeholder
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // App description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                AppConstants.appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),

            // Loading text
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
