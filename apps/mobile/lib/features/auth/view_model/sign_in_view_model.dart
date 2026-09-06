import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers.dart';

part 'sign_in_view_model.g.dart';

/// Drives the sign-in screen's two buttons.
///
/// State is `void` — there's nothing to render on success, since a
/// successful sign-in flips [authStateProvider] and the router redirects
/// away from the sign-in screen on its own.
@riverpod
class SignInViewModel extends _$SignInViewModel {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthServiceProvider).signInWithGoogle();
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthServiceProvider).signInWithApple();
    });
  }
}
