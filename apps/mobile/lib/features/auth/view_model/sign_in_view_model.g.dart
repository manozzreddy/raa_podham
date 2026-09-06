// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the sign-in screen's two buttons.
///
/// State is `void` — there's nothing to render on success, since a
/// successful sign-in flips [authStateProvider] and the router redirects
/// away from the sign-in screen on its own.

@ProviderFor(SignInViewModel)
final signInViewModelProvider = SignInViewModelProvider._();

/// Drives the sign-in screen's two buttons.
///
/// State is `void` — there's nothing to render on success, since a
/// successful sign-in flips [authStateProvider] and the router redirects
/// away from the sign-in screen on its own.
final class SignInViewModelProvider
    extends $AsyncNotifierProvider<SignInViewModel, void> {
  /// Drives the sign-in screen's two buttons.
  ///
  /// State is `void` — there's nothing to render on success, since a
  /// successful sign-in flips [authStateProvider] and the router redirects
  /// away from the sign-in screen on its own.
  SignInViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInViewModelHash();

  @$internal
  @override
  SignInViewModel create() => SignInViewModel();
}

String _$signInViewModelHash() => r'6b2e0c048e1e11ae08515bb5868bab0d6898a06c';

/// Drives the sign-in screen's two buttons.
///
/// State is `void` — there's nothing to render on success, since a
/// successful sign-in flips [authStateProvider] and the router redirects
/// away from the sign-in screen on its own.

abstract class _$SignInViewModel extends $AsyncNotifier<void> {
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
