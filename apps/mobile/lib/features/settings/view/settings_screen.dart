import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../../services/theme_mode_repository.dart';
import '../../../theme/theme.dart';
import '../../../widgets/sheet_drag_handle.dart';

/// Lets the signed-in user pick the app's appearance (device default /
/// light / dark) and sign out. Reads/writes [themeModeControllerProvider]
/// and calls [FirebaseAuthService.signOut] directly — both cross-feature
/// `services/`, so there's no feature-local ViewModel to go through, the
/// same way [HomeScreen]'s own sign-out action already worked.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode =
        ref.watch(themeModeControllerProvider).value ?? AppThemeMode.light;

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

  /// Same confirm-then-sign-out action sheet [HomeScreen]'s profile avatar
  /// used to open directly — now one tap further in, behind Settings.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    Future<void> signOut() => ref.read(firebaseAuthServiceProvider).signOut();

    if (isCupertino) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const SheetDragHandle(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                signOut();
              },
            ),
          ],
        ),
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
    if (isCupertino) {
      return CupertinoListTile(
        title: const Text(
          'Sign out',
          style: TextStyle(color: CupertinoColors.destructiveRed),
        ),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Sign out', style: TextStyle(color: Colors.red)),
      onTap: onTap,
    );
  }
}
