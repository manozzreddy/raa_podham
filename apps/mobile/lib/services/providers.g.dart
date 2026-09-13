// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cross-feature singletons. `keepAlive: true` because these back the
/// router's auth redirect and every feature's repositories — they must
/// outlive any single screen.

@ProviderFor(firebaseAuthService)
final firebaseAuthServiceProvider = FirebaseAuthServiceProvider._();

/// Cross-feature singletons. `keepAlive: true` because these back the
/// router's auth redirect and every feature's repositories — they must
/// outlive any single screen.

final class FirebaseAuthServiceProvider
    extends
        $FunctionalProvider<
          FirebaseAuthService,
          FirebaseAuthService,
          FirebaseAuthService
        >
    with $Provider<FirebaseAuthService> {
  /// Cross-feature singletons. `keepAlive: true` because these back the
  /// router's auth redirect and every feature's repositories — they must
  /// outlive any single screen.
  FirebaseAuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthServiceHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuthService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAuthService create(Ref ref) {
    return firebaseAuthService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuthService>(value),
    );
  }
}

String _$firebaseAuthServiceHash() =>
    r'b482742efbd79dafa55708aa0199b0a5d0c257a9';

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'd1f63a7eac9284e10633af81c063c3633c83a7ff';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'22083b50dff6cf65e092e8447f1c11fdee0a6b69';

/// The app's current appearance choice — read by [RaaPodhamApp] on every
/// build (to pick a `ThemeMode`/`Brightness`) and set from the Settings
/// screen, so it lives here rather than under `features/settings/` the
/// same way [authState] does.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// The app's current appearance choice — read by [RaaPodhamApp] on every
/// build (to pick a `ThemeMode`/`Brightness`) and set from the Settings
/// screen, so it lives here rather than under `features/settings/` the
/// same way [authState] does.
final class ThemeModeControllerProvider
    extends $AsyncNotifierProvider<ThemeModeController, AppThemeMode> {
  /// The app's current appearance choice — read by [RaaPodhamApp] on every
  /// build (to pick a `ThemeMode`/`Brightness`) and set from the Settings
  /// screen, so it lives here rather than under `features/settings/` the
  /// same way [authState] does.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();
}

String _$themeModeControllerHash() =>
    r'f793fb73f6cb753972488f891503eacea04de1e7';

/// The app's current appearance choice — read by [RaaPodhamApp] on every
/// build (to pick a `ThemeMode`/`Brightness`) and set from the Settings
/// screen, so it lives here rather than under `features/settings/` the
/// same way [authState] does.

abstract class _$ThemeModeController extends $AsyncNotifier<AppThemeMode> {
  FutureOr<AppThemeMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppThemeMode>, AppThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppThemeMode>, AppThemeMode>,
              AsyncValue<AppThemeMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
