import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/api_client.dart';
import '../../../services/providers.dart';

part 'account_repository.g.dart';

/// Talks to the Cloud Run backend's account endpoint — only read by the
/// settings feature's [SettingsViewModel], so this stays feature-local
/// rather than living in `services/`.
class AccountRepository {
  AccountRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Permanently deletes the signed-in user's account: every ride they
  /// host is force-ended and deleted, every ride they just ride in loses
  /// their membership, and their Firestore profile, Storage uploads, and
  /// Firebase Auth user are all removed server-side.
  Future<void> deleteAccount() async {
    await _apiClient.delete<void>('/users/me');
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    AccountRepository(ref.watch(apiClientProvider));
