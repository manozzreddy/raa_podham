---
trigger: always_on
---

# Architecture Rules

MVVM, backed by Riverpod (code generation style, `AsyncNotifier` for
ViewModels). No BLoC, no manual `Provider()`/`StateNotifierProvider()`
construction, no Clean-Architecture usecase layer — keep it to
View / ViewModel / Repository, plus a `services/` layer for cross-feature
singletons (auth, the API client).

## Feature Folder Structure

One folder per feature under `lib/features/`:

```
lib/features/<feature>/
  view/            Views — ConsumerWidget/ConsumerStatefulWidget, one per screen
  view_model/       ViewModel(s) — @riverpod AsyncNotifier classes
  data/             Repository interfaces + implementations
  models/           Plain data classes, pure helpers
  widgets/          Screen-local widgets, not reused elsewhere
```

Cross-feature singletons (things every feature can depend on, that
outlive any one screen) live in `lib/services/` instead: `FirebaseAuthService`,
`ApiClient`, and their `@Riverpod(keepAlive: true)` providers in
`services/providers.dart`. `lib/theme/` is the other thing that lives
outside `features/`, for the same reason — genuinely cross-cutting, not
owned by one feature.

**Where a repository/service lives is decided by who reads it, not what
domain concept it represents.** `FirebaseAuthService` sounds like it
belongs to the `auth` feature, but it doesn't live there: `ApiClient`
needs it for every backend call regardless of feature, `app.dart`'s
router needs it to gate every route, and `features/home/data/` reads
`currentUser` too — three consumers outside `auth`, so it's cross-feature
infrastructure and belongs in `services/`. If something in `data/` only
ever gets read by its own feature's ViewModel(s), it stays put; the
moment a second feature (or the router, or another service) needs it
directly, move it to `services/` rather than reaching into that
feature's folder from outside.

Same encapsulation rule as `data/` repositories, one level up:
`FirebaseAuthService` is the only class that imports `firebase_auth`,
`google_sign_in`, or `sign_in_with_apple` directly. A ViewModel or View
may reference `User`/`UserCredential` for typing, but should never call
into those packages' SDKs itself.

`lib/app.dart` holds the app root widget and the `GoRouter` provider.
`lib/main.dart` is just the entrypoint: `Firebase.initializeApp()` then
`runApp(ProviderScope(child: RaaPodhamApp()))`.

## Shared Widgets

Same promotion rule as repositories/services, applied to widgets: a
widget starts in its own feature's `widgets/` — even if it's reused more
than once *within* that feature. It only moves to `lib/widgets/` (a
top-level folder, sibling to `theme/`/`services/`, created the first
time something actually qualifies) once a **second feature** needs the
same widget too. Reuse within one feature isn't promotion-worthy on its
own; cross-feature reuse is.

Before writing a new one-off button/chip/etc., check `lib/widgets/`
first and prefer the shared version over rewriting it — that's what
keeps things looking consistent across features.

## Layers

- **View** (`ConsumerWidget`/`ConsumerStatefulWidget`, in `view/`): renders
  `ref.watch(fooViewModelProvider)` — an `AsyncValue`, handled with
  `.when(loading:, error:, data:)` — and forwards user actions to
  `ref.read(fooViewModelProvider.notifier)`. Owns widget-level concerns
  the ViewModel shouldn't know about: `BuildContext`, `Navigator`,
  `MapController` and similar platform/widget controllers, animation
  controllers. React to ViewModel state changes that need to drive one of
  these with `ref.listen` rather than moving the controller itself into
  the ViewModel.
- **ViewModel** (`@riverpod class FooViewModel extends _$FooViewModel`,
  an `AsyncNotifier`, in `view_model/`): holds UI state as one immutable
  state class wrapped in `AsyncValue`, exposes intent methods
  (`recenter()`, `onSheetExtentChanged(extent)`, ...) that update `state`.
  Reads repositories and `services/` singletons via `ref.watch`/`ref.read`.
  Never imports `package:flutter/material.dart` or holds a `BuildContext`.
  If a mutation needs the data from the last successful `build()` (rather
  than re-fetching), cache it on the Notifier instance — plain fields on
  a `Notifier`/`AsyncNotifier` persist across `build()` reruns and across
  `state` reassignments from other methods.
- **Repository** (in `data/`): wraps one external data source —
  Firestore, Realtime Database, or the HTTP client — behind a plain
  class, exposed through a `@riverpod` provider function. **Repositories
  are the only classes that import `cloud_firestore` / `firebase_database`
  / `dio` directly** — a ViewModel or View importing one of those is a
  bug. This is the seam a real backend drops into later: swap what a
  provider function returns, and nothing above it changes.

```dart
// ✅ Correct — Repository behind a provider, swappable in one place
@riverpod
RideRepository rideRepository(Ref ref) => RideRepository(ref.watch(apiClientProvider));

// ❌ Avoid — a ViewModel importing cloud_firestore/dio directly
class HomeViewModel extends _$HomeViewModel {
  final _firestore = FirebaseFirestore.instance; // belongs in a Repository
}
```

Combining more than one repository's stream for a single screen (e.g.
Realtime Database positions + Firestore profiles) gets its own
`@riverpod` function in `data/`, not inline in the ViewModel — see
`features/home/data/riders_for_ride.dart`.

## Riverpod: Code Generation Only

Use `@riverpod`/`@Riverpod(keepAlive: true)` (from `riverpod_annotation`)
on a function or a `Notifier`/`AsyncNotifier` class, not the manual
`Provider((ref) => ...)`/`NotifierProvider(...)` constructors:

```dart
part 'home_view_model.g.dart';

// ✅ Correct
@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  Future<HomeState> build(String rideId) async => ...;
}

// ❌ Avoid — manual provider construction
final homeViewModelProvider = AsyncNotifierProvider.family<HomeViewModel, HomeState, String>(HomeViewModel.new);
```

Every file that declares a provider needs `part '<file_name>.g.dart';` at
the top, matching the file's own name. After adding or changing a
provider, regenerate:

```
dart run build_runner build --delete-conflicting-outputs
```

(`dart run build_runner watch` while actively iterating on providers.)
**Commit the generated `.g.dart` files** — they're not gitignored in this
project, so `flutter run`/`flutter analyze` work right after a fresh
clone without anyone needing to know to run codegen first.

## Wiring

- `main.dart` wraps the app root in a single `ProviderScope` — once, at
  the `runApp()` call, not inside the `App` widget itself.
- Widget tests wrap whatever they pump in their own `ProviderScope`,
  overriding any provider that would otherwise touch real Firebase/network
  (e.g. `firebaseAuthServiceProvider.overrideWithValue(_FakeFirebaseAuthService())`)
  — never let a test depend on Firebase actually being initialized.
- `riverpod_lint` is wired into `analysis_options.yaml` via the native
  `plugins:` key (not `custom_lint` — that package is stuck on an older
  `analyzer` version and actually conflicts with `riverpod_generator` as
  of this writing). Keep the pinned version there in sync with
  `pubspec.yaml`'s `riverpod_lint` entry.
