# Icon assets

`launcher_icon/icon.png` and `launcher_icon/icon_foreground.png` are the
launcher-icon-generation source, read only by `flutter_launcher_icons` —
nothing in the app's own UI should reference this folder. Both are
rendered from `mark.svg` (Sunrise Amber `#FF7A33` seed, Predawn Indigo
`#1C2541` backing) — edit the SVG and re-render both PNGs if the mark
ever changes.

`icon_foreground.png` is pre-scaled to sit inside Android's adaptive-icon
safe zone (a 66%-diameter circle from center, verified by overlay) — keep
that margin if it's regenerated.

`icons/` holds small icons the app UI actually renders (via
`Image.asset`), first- or third-party:
- `app_mark.png` — a copy of `launcher_icon/icon_foreground.png`, used
  where the UI needs the mark itself (e.g. the sign-in screen's badge).
  Re-copy it if `mark.svg` changes.
- `google_g.png` — Google's own "G" mark, from
  `developers.google.com/identity/images/g-logo.png`, used on the
  "Continue with Google" button.

Generation config for `launcher_icon/` lives in `apps/mobile/pubspec.yaml`
under `flutter_launcher_icons:`. After changing the source images,
regenerate with:

```
flutter pub get
dart run flutter_launcher_icons
```
