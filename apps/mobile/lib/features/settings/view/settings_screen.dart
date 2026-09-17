import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../../services/theme_mode_repository.dart';
import '../../../theme/theme.dart';
import '../view_model/settings_view_model.dart';

/// Lets the signed-in user pick the app's appearance (device default /
/// light / dark), sign out, or delete their account. Sign-out
/// reads/writes [themeModeControllerProvider] and calls
/// [FirebaseAuthService.signOut] directly — both cross-feature
/// `services/`, so there's no feature-local ViewModel to go through, the
/// same way [HomeScreen]'s own sign-out action already worked. Deleting
/// the account goes through [SettingsViewModel] instead, since (unlike
/// sign-out) it's a network call that needs loading/error state.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode =
        ref.watch(themeModeControllerProvider).value ?? AppThemeMode.light;
    final deletionState = ref.watch(settingsViewModelProvider);

    ref.listen<AsyncValue<void>>(settingsViewModelProvider, (previous, next) {
      if (next.hasError) {
        // Never the raw next.error here — same rule AppErrorScreen follows,
        // it's not fit for a user to read.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete account. Try again.")),
        );
      }
    });

    void selectThemeMode(AppThemeMode mode) =>
        ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);

    final content = ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _SectionHeader('Appearance'),
        _ThemeModeTile(
          label: 'Device default',
          mode: AppThemeMode.system,
          selectedMode: selectedMode,
          onSelect: selectThemeMode,
        ),
        _ThemeModeTile(
          label: 'Light',
          mode: AppThemeMode.light,
          selectedMode: selectedMode,
          onSelect: selectThemeMode,
        ),
        _ThemeModeTile(
          label: 'Dark',
          mode: AppThemeMode.dark,
          selectedMode: selectedMode,
          onSelect: selectThemeMode,
        ),
        const SizedBox(height: 24),
        const _SectionHeader('Account'),
        _SignOutTile(onTap: () => _confirmSignOut(context, ref)),
        // Deliberately its own section, well below Sign out and the only
        // red row on the screen — Sign out and Delete account used to sit
        // back-to-back, both red, and were easy to mis-tap for each other.
        const SizedBox(height: 32),
        const _SectionHeader('Danger Zone'),
        _DeleteAccountTile(
          isLoading: deletionState.isLoading,
          onTap: deletionState.isLoading
              ? null
              : () => _confirmDeleteAccount(context, ref),
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: content,
    );
  }

  /// Same dialog shape as [_confirmDeleteAccount] (title + message +
  /// Cancel/confirm), not that one's destructive styling — signing out
  /// loses nothing, it's just a plain confirmation.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    Future<void> signOut() => ref.read(firebaseAuthServiceProvider).signOut();

    if (isCupertino) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Sign out?'),
          content: const Text("You can sign back in anytime."),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text("You can sign back in anytime."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  /// Unlike [_confirmSignOut]'s action sheet, this is a dialog with actual
  /// warning copy — deleting the account is irreversible and, unlike
  /// signing out, destroys data other ride members rely on too (any ride
  /// this user hosts), so a plain destructive button label isn't enough.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    const title = 'Delete account?';
    const message =
        "This permanently deletes your account. Any rides you're hosting "
        "will be ended and deleted for everyone in them, and you'll be "
        "removed from rides you've joined. This action can't be undone.";

    Future<void> deleteAccount() =>
        ref.read(settingsViewModelProvider.notifier).deleteAccount();

    if (isCupertino) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text(title),
          content: const Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                deleteAccount();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(title),
        content: const Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelLarge;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: style?.copyWith(color: style.color?.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.label,
    required this.mode,
    required this.selectedMode,
    required this.onSelect,
  });

  final String label;
  final AppThemeMode mode;
  final AppThemeMode selectedMode;
  final ValueChanged<AppThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selectedMode;
    final checkmark = isSelected
        ? Icon(
            isCupertino ? CupertinoIcons.check_mark : Icons.check,
            color: AppColors.sunriseAmber,
          )
        : null;

    if (isCupertino) {
      return CupertinoListTile(
        title: Text(label),
        trailing: checkmark,
        onTap: () => onSelect(mode),
      );
    }
    return ListTile(
      title: Text(label),
      trailing: checkmark,
      onTap: () => onSelect(mode),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Deliberately not styled as destructive (unlike _DeleteAccountTile) —
    // signing out loses nothing, and red was making it look just as
    // dangerous as, and easy to mis-tap for, delete account right below it.
    if (isCupertino) {
      return CupertinoListTile(title: const Text('Sign out'), onTap: onTap);
    }
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Sign out'),
      onTap: onTap,
    );
  }
}

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailing = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: isCupertino
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(strokeWidth: 2),
          )
        : null;

    if (isCupertino) {
      return CupertinoListTile(
        title: const Text(
          'Delete account',
          style: TextStyle(color: CupertinoColors.destructiveRed),
        ),
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Delete account', style: TextStyle(color: Colors.red)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
