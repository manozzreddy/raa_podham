import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers.dart';
import '../data/account_repository.dart';

part 'settings_view_model.g.dart';

/// Drives the Settings screen's delete-account action. Sign-out doesn't
/// need a ViewModel (see [SettingsScreen]'s doc comment) since it's
/// fire-and-forget, but deletion needs loading/error state to show while
/// its backend call is in flight.
///
/// State is `void` on success — nothing to render, since deleting the
/// Firebase Auth user flips [authStateProvider] and the router redirects
/// to the sign-in screen on its own, the same way a plain sign-out does.
@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  Future<void> build() async {}

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).deleteAccount();
      await ref.read(firebaseAuthServiceProvider).signOut();
    });
    if (!ref.mounted) return;
    state = result;
  }
}
