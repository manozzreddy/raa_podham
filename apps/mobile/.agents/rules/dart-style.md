---
trigger: always_on
---

# Dart Style Rules

## Static-Namespace Classes

A class that only groups related `static` members (e.g. `AppColors`,
`AppTheme`) — no instance state, nothing to construct — must be declared
`abstract final class`:

```dart
// ✅ Correct
abstract final class AppColors {
  static const Color sunriseAmber = Color(0xFFFF7A33);
}

// ❌ Avoid
class AppColors {
  static const Color sunriseAmber = Color(0xFFFF7A33);
}
```

- `abstract` blocks direct instantiation (`AppColors()`), since an instance
  would hold no state.
- `final` blocks `extends`/`implements`/`with` from anywhere, so the
  namespace can't be subclassed or overridden.
- This replaces the older private-constructor trick (`AppColors._();`),
  which only blocked instantiation and left subclassing open.

---

## Code Comments

Do not add unnecessary comments. Code should be self-documenting. Only add
a comment when it carries information the code itself can't — a
non-obvious "why", a gotcha, or a constraint coming from outside the file
(a platform quirk, an external API behavior, a spec requirement).

```dart
// ❌ Avoid — restates what the code already says
// Increment the counter by one.
counter++;

// ✅ Correct — explains a non-obvious "why"
// CupertinoApp has no themeMode/darkTheme split like MaterialApp does,
// so brightness must be resolved and passed in explicitly.
static CupertinoThemeData themeFor(Brightness brightness) { ... }
```

Prefer a clearer name or a smaller function over a comment explaining an
unclear one.
