import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers.dart';
import '../data/user_profile_repository.dart';

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
    if (!state.hasError) unawaited(_syncUserProfile());
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthServiceProvider).signInWithApple();
    });
    if (!state.hasError) unawaited(_syncUserProfile());
  }

  /// Writes the signed-in user's profile to Firestore so the backend can
  /// populate a ride member's displayName/photoUrl from it. Best-effort
  /// and fire-and-forget — the user is already signed in regardless of
  /// whether this succeeds, so it must never fail the sign-in itself.
  Future<void> _syncUserProfile() async {
    try {
      final user = ref.read(firebaseAuthServiceProvider).currentUser;
      if (user == null) return;
      await ref
          .read(userProfileRepositoryProvider)
          .upsertCurrentUserProfile(
            uid: user.uid,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            email: user.email,
          );
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }
}
