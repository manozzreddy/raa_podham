# SnackBar Feedback

For a brief, non-navigating result of something the user just did —
usually a failed action, sometimes a quick confirmation — use a
`SnackBar` via `ScaffoldMessenger.of(context).showSnackBar(...)`, worded
and guarded consistently:

```dart
Future<void> _handleSomeAction() async {
  try {
    await ref.read(someRepositoryProvider).doTheThing();
  } catch (_) {
    if (!mounted) return; // `context.mounted` outside a State class
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't do the thing. Try again.")),
    );
    return;
  }
}
```

## Wording

- A failure: **"Couldn't \<what didn't happen>. Try again."** —
  contraction ("Couldn't", not "Could not"), no "please", ends on "Try
  again." Examples already in this shape:
  `RideDetailScreen._confirmAndDelete`/`_handleStartNow`,
  `HomeScreen._handleEndOrLeaveRide`/`_handleRemoveRider`
  (`features/home/view/home_screen.dart`).
- Never interpolate the raw exception/error object into the message —
  same rule `AppErrorScreen` already states for its own `message`: it's
  not something a user should have to read. State what failed in plain
  words instead (see the fix in `SettingsScreen`'s delete-account error
  listener).
- A quick confirmation (not an error) doesn't need "Try again" — just
  say what happened: `'Invite code copied'`
  (`features/rides/view/share_invite_screen.dart`). Keep it just as
  short.
- If there's a concrete next step other than retrying, say that instead
  of "Try again" — e.g. `about_screen.dart`'s "No UPI app found — copy
  the UPI ID instead."

## Mount check before showing

Always confirm the widget is still mounted right before calling
`showSnackBar`, using whichever the surrounding code already is:

- `if (!mounted) return;` inside a `State`/`ConsumerState` method.
- `if (!context.mounted) return;` inside a plain function that only has
  a `BuildContext`, not a `State` (e.g. a local function declared inside
  a `ConsumerWidget.build`).

Not needed inside a `ref.listen` callback registered during `build()` —
Riverpod already scopes that listener's lifetime to the widget, so it
can't fire after the widget's gone.
