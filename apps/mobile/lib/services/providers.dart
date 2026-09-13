import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'firebase_auth_service.dart';
import 'theme_mode_repository.dart';

part 'providers.g.dart';

/// Cross-feature singletons. `keepAlive: true` because these back the
/// router's auth redirect and every feature's repositories — they must
/// outlive any single screen.
@Riverpod(keepAlive: true)
FirebaseAuthService firebaseAuthService(Ref ref) => FirebaseAuthService();

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) =>
    ref.watch(firebaseAuthServiceProvider).authStateChanges();

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) =>
    ApiClient(ref.watch(firebaseAuthServiceProvider));

/// The app's current appearance choice — read by [RaaPodhamApp] on every
/// build (to pick a `ThemeMode`/`Brightness`) and set from the Settings
/// screen, so it lives here rather than under `features/settings/` the
/// same way [authState] does.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  Future<AppThemeMode> build() =>
      ref.watch(themeModeRepositoryProvider).loadThemeMode();

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(themeModeRepositoryProvider).saveThemeMode(mode);
  }
}
