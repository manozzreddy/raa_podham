# Tap Feedback

Anything the user perceives as a button, row, chip, or link — not a plain
form field — must show visible press feedback. Never a bare
`GestureDetector` with no visual response for something that reads as an
action.

## Prefer an actual button widget

If the content fits a standard shape, use a real button rather than
hand-rolling a tappable region:

- `TextButton`/`FilledButton`/`ElevatedButton`/`IconButton` (Material),
  `CupertinoButton`/`CupertinoButton.filled` (Cupertino) — already used
  this way throughout `dialogs.md`'s confirmation dialogs and
  `SheetActionButton`.
- `ListTile`/`CupertinoListTile` for a row — already provides its own
  tap feedback, nothing extra to add (see every tile in
  `SettingsScreen`, `PastRidesScreen`).

## Custom content that isn't a standard button shape

When the tappable thing is fully custom-styled (an icon+text row, a
photo placeholder, a small "×" overlay) and no built-in button fits,
wrap it the same way `_AddPhotoTarget`, `_RemovePhotoButton`, and
`_ClearScheduledHint` do (all in
`features/rides/view/create_ride_screen.dart`):

```dart
final button = isCupertino
    ? CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: content,
      )
    : Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );

// If this sits directly in something that hands out full-width tight
// constraints (a ListView item, a Column with stretch alignment), both
// CupertinoButton and InkWell fill that whole box — the tappable/ink
// area stretches across it even though `content` itself is narrow.
// Align loosens the constraint so the button shrink-wraps to `content`
// instead, and only that shrunk box sits at `alignment`.
return Align(alignment: Alignment.centerLeft, child: button);
```

`Material(color: Colors.transparent, ...)` is required — `InkWell`
can't paint its splash without a `Material` ancestor. Skip the `Align`
wrapper only when the surrounding layout already gives this loose
constraints on its own (e.g. it's already inside a `Row`/`Wrap`) — check
by comparing the ink/press highlight's bounds against `content`'s actual
size, not just how it looks unpressed.

## The one deliberate exception

A field that's read-only and styled as a real `TextField`/
`CupertinoTextField`, wrapped in `GestureDetector`+`AbsorbPointer` to
turn the whole thing into "tap to open a picker" (the destination and
scheduled-time fields in `create_ride_screen.dart`) — this intentionally
gets **no** ink/opacity feedback, the same way a real text field shows
none when you tap it to focus. Don't add ripple here; it would look like
a different kind of control than the text field it's meant to read as.
Any other bare `GestureDetector` (a hint line, a custom row, anything
that isn't imitating a text field) needs feedback per above — the bug
`_ClearScheduledHint` had before this rule was written.
