# Guarding State After an Async Gap

Any ViewModel method that `await`s something and then touches `state` or
`ref` again afterward must check `ref.mounted` right after the `await`,
before that next line:

```dart
Future<void> doSomething() async {
  final result = await someRepository.fetchThing();
  // The screen could have been navigated away from while the await
  // above was pending, disposing this auto-dispose provider — touching
  // `ref`/`state` after that throws UnmountedRefException.
  if (!ref.mounted) return;
  state = state.copyWith(thing: result);
}
```

## Why

Every ViewModel in this app is an auto-dispose `@riverpod`
`Notifier`/`AsyncNotifier` (see `architecture.md`) — Riverpod disposes it
the moment nothing's watching it anymore, which can happen mid-`await`
(the user navigated away, the ride ended and the screen swapped out from
under them, etc.). Writing to `state` — or reading `ref` again for
anything else — on a disposed provider throws `UnmountedRefException` at
runtime. There's no compiler check for this; it only ever shows up when
the timing actually lines up wrong, which is exactly why it's easy to
skip and easy to miss in review.

Reference implementations: `HomeViewModel._resolvePositionReporting`
(`features/home/view_model/home_view_model.dart`),
`LocationPermissionViewModel.requestPermission`/`refreshStatus`
(`features/location_permission/view_model/location_permission_view_model.dart`),
`NoActiveRideViewModel.recenter`/`_resolveInitialLocation`
(`features/home/view_model/no_active_ride_view_model.dart`),
`CreateRideViewModel.pickAndUploadCoverPhoto`
(`features/rides/view_model/create_ride_view_model.dart`).

Write the actual reasoning once per method if it's non-obvious why
*that* await is a real race (e.g. two calls that can finish in either
order); a one-line "same guard, same reason as X" pointing at one other
occurrence is fine for a plain "user could've navigated away" case —
don't chain more than one level of that, or the reasoning becomes
unfindable.

## What doesn't need this

- Anything before the method's first `await` — nothing async has
  happened yet, so the provider can't have been disposed out from under
  it.
- A `build()` method's own initial synchronous portion, for the same
  reason.
- A `Future` deliberately fired with `unawaited(...)` specifically
  *because* its own internals already guard themselves before touching
  `state`/`ref` — the guard belongs inside that future, not at the call
  site.
- Providers annotated `@Riverpod(keepAlive: true)` (`services/providers.dart`)
  — these never get disposed mid-session, so there's nothing to guard
  against. This only applies to the auto-dispose ViewModels.
