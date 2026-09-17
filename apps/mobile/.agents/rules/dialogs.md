# Confirmation Dialogs

Before any action the user should pause on before doing — signing out,
deleting something, ending/leaving a ride, etc. — use a platform dialog
(`AlertDialog` / `CupertinoAlertDialog`), not a bottom sheet or action
sheet. A title, one line of message, Cancel, and the action itself:

```dart
Future<void> _confirmSomething(BuildContext context, WidgetRef ref) async {
  const title = 'Do the thing?';
  const message = 'One sentence saying what happens and whether it can be undone.';

  Future<void> doTheThing() => ref.read(someViewModelProvider.notifier).doTheThing();

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
            isDestructiveAction: true, // only if doTheThing() is destructive
            onPressed: () {
              Navigator.of(dialogContext).pop();
              doTheThing();
            },
            child: const Text('Do it'),
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
            doTheThing();
          },
          child: const Text(
            'Do it',
            // Only red if doTheThing() is destructive — see below.
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
```

Reference implementations: `RideDetailScreen._confirmDelete` (delete a
past ride), `SettingsScreen._confirmSignOut` and
`SettingsScreen._confirmDeleteAccount` (`features/settings/view/settings_screen.dart`).

## Destructive vs. plain

Only style the confirming action as destructive (`isDestructiveAction:
true` on Cupertino, red `TextStyle` on Material) when it's actually
irreversible or loses data — deleting a ride, deleting an account.
Signing out isn't destructive (nothing is lost, signing back in undoes
it completely), so `_confirmSignOut`'s dialog uses the same neutral
button styling as Cancel. Don't reach for red just because an action
feels "final" — reserve it for the actions that actually are.

The same distinction applies to whatever tile/button opens the dialog
in the first place: a genuinely destructive action's row can be red
(see `_DeleteAccountTile`), but a non-destructive one (`_SignOutTile`)
shouldn't be, for the same reason two red rows next to each other are
easy to mis-tap between one another — see `SettingsScreen`'s "Danger
Zone" section, kept visually separate from "Account" for exactly this.

## What this isn't for

This is specifically for **confirm-before-you-act** prompts. It doesn't
replace bottom sheets used for their own purpose — a picker
(`CreateRideScreen`'s scheduled-time picker), a list of choices/content
(`AboutScreen`'s support sheet, `HomeScreen`'s Rider Info modal). Those
stay `showModalBottomSheet`/`showCupertinoModalPopup`; only convert one
to this pattern if it's actually asking "are you sure?" before doing
something.
