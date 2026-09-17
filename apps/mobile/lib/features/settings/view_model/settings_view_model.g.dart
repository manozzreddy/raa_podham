// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the Settings screen's delete-account action. Sign-out doesn't
/// need a ViewModel (see [SettingsScreen]'s doc comment) since it's
/// fire-and-forget, but deletion needs loading/error state to show while
/// its backend call is in flight.
///
/// State is `void` on success — nothing to render, since deleting the
/// Firebase Auth user flips [authStateProvider] and the router redirects
/// to the sign-in screen on its own, the same way a plain sign-out does.

@ProviderFor(SettingsViewModel)
final settingsViewModelProvider = SettingsViewModelProvider._();

/// Drives the Settings screen's delete-account action. Sign-out doesn't
/// need a ViewModel (see [SettingsScreen]'s doc comment) since it's
/// fire-and-forget, but deletion needs loading/error state to show while
/// its backend call is in flight.
///
/// State is `void` on success — nothing to render, since deleting the
/// Firebase Auth user flips [authStateProvider] and the router redirects
/// to the sign-in screen on its own, the same way a plain sign-out does.
final class SettingsViewModelProvider
    extends $AsyncNotifierProvider<SettingsViewModel, void> {
  /// Drives the Settings screen's delete-account action. Sign-out doesn't
  /// need a ViewModel (see [SettingsScreen]'s doc comment) since it's
  /// fire-and-forget, but deletion needs loading/error state to show while
  /// its backend call is in flight.
  ///
  /// State is `void` on success — nothing to render, since deleting the
  /// Firebase Auth user flips [authStateProvider] and the router redirects
  /// to the sign-in screen on its own, the same way a plain sign-out does.
  SettingsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsViewModelHash();

  @$internal
  @override
  SettingsViewModel create() => SettingsViewModel();
}

String _$settingsViewModelHash() => r'8d1241175722e7e3b1a2a939b8c1b9977e5c35db';

/// Drives the Settings screen's delete-account action. Sign-out doesn't
/// need a ViewModel (see [SettingsScreen]'s doc comment) since it's
/// fire-and-forget, but deletion needs loading/error state to show while
/// its backend call is in flight.
///
/// State is `void` on success — nothing to render, since deleting the
/// Firebase Auth user flips [authStateProvider] and the router redirects
/// to the sign-in screen on its own, the same way a plain sign-out does.

abstract class _$SettingsViewModel extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
