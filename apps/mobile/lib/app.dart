import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'features/auth/view/sign_in_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/rides/view/create_ride_screen.dart';
import 'features/rides/view/join_ride_screen.dart';
import 'features/rides/view/rides_list_screen.dart';
import 'services/providers.dart';
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

    if (isCupertino) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      return CupertinoApp.router(
        title: _title,
        debugShowCheckedModeBanner: false,
        theme: AppCupertinoTheme.themeFor(brightness),
        routerConfig: router,
      );
    }

    return MaterialApp.router(
      title: _title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
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
    initialLocation: '/rides',
    redirect: (context, state) {
      final isAuthed = ref.read(authStateProvider).value != null;
      final isSigningIn = state.matchedLocation == '/sign-in';

      if (!isAuthed) return isSigningIn ? null : '/sign-in';
      if (isSigningIn) return '/rides';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (context, state) => const SignInScreen()),
      GoRoute(path: '/rides', builder: (context, state) => const RidesListScreen()),
      GoRoute(path: '/rides/create', builder: (context, state) => const CreateRideScreen()),
      GoRoute(path: '/rides/join', builder: (context, state) => const JoinRideScreen()),
      GoRoute(
        path: '/rides/:rideId/home',
        builder: (context, state) => HomeScreen(rideId: state.pathParameters['rideId']!),
      ),
    ],
  );
}
