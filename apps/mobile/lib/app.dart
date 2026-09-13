import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'features/about/view/about_screen.dart';
import 'features/auth/view/sign_in_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/rides/models/ride.dart';
import 'features/rides/view/create_ride_screen.dart';
import 'features/rides/view/destination_search_screen.dart';
import 'features/rides/view/join_ride_screen.dart';
import 'features/rides/view/share_invite_screen.dart';
import 'features/settings/view/settings_screen.dart';
import 'features/splash/view/splash_screen.dart';
import 'services/providers.dart';
import 'services/theme_mode_repository.dart';
import 'theme/theme.dart';

part 'app.g.dart';

/// The app root: [CupertinoApp.router] on iOS, [MaterialApp.router]
/// everywhere else, both driven by [appRouterProvider].
class RaaPodhamApp extends ConsumerWidget {
  const RaaPodhamApp({super.key});

  static const String _title = 'Raa Podham';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Falls back to light while the persisted choice is still loading (a
    // one-off SharedPreferences read) rather than gating the whole app
    // behind a loader for it.
    final appThemeMode =
        ref.watch(themeModeControllerProvider).value ?? AppThemeMode.light;

    if (isCupertino) {
      final brightness = switch (appThemeMode) {
        AppThemeMode.system => MediaQuery.platformBrightnessOf(context),
        AppThemeMode.light => Brightness.light,
        AppThemeMode.dark => Brightness.dark,
      };
      return CupertinoApp.router(
        title: _title,
        debugShowCheckedModeBanner: false,
        theme: AppCupertinoTheme.themeFor(brightness),
        routerConfig: router,
      );
    }

    final themeMode = switch (appThemeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
    return MaterialApp.router(
      title: _title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Notifies [GoRouter] to re-run its `redirect` whenever
/// [authStateProvider] changes, so signing in/out immediately re-routes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

@riverpod
GoRouter appRouter(Ref ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: '/splash',
    redirect: (context, state) {
      // SplashScreen picks its own destination once the launch animation
      // finishes and auth state resolves — the redirect would otherwise
      // bounce it straight to /sign-in before the animation ever plays.
      if (state.matchedLocation == '/splash') return null;

      final isAuthed = ref.read(authStateProvider).value != null;
      final isSigningIn = state.matchedLocation == '/sign-in';

      if (!isAuthed) return isSigningIn ? null : '/sign-in';
      if (isSigningIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      // The landing screen: it resolves the signed-in user's active ride
      // (or lack of one) itself, so no rideId/extra needs to travel
      // through the URL — unlike the old per-ride route, that means a web
      // refresh or a restored route lands here in the right state too.
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/rides/create',
        builder: (context, state) => const CreateRideScreen(),
      ),
      GoRoute(
        path: '/rides/destination-search',
        builder: (context, state) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: '/rides/join',
        builder: (context, state) => const JoinRideScreen(),
      ),
      GoRoute(
        path: '/rides/share-invite',
        builder: (context, state) =>
            ShareInviteScreen(ride: state.extra! as Ride),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    ],
  );
}
