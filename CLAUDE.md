# Raa Podham

Free Flutter group-riding app — a live location overlay of a riding group on
a map. No in-app navigation.

## Structure

Monorepo.

- `apps/mobile` — the Flutter app (org id `com.dynamicarraytech`), targets
  Android, iOS, and Web. Coding conventions for this app live in
  `apps/mobile/CLAUDE.md` and `apps/mobile/.agents/rules/`.
- Repo root also holds Firebase config (`firebase.json`, `firestore.rules`,
  `storage.rules`, `database.rules.json`) shared across apps.
