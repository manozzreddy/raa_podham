import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_repository.g.dart';

/// The user's appearance preference: follow the OS setting, or force one
/// mode regardless of it. Deliberately its own enum rather than Flutter's
/// `ThemeMode` so the services layer doesn't need to import
/// `package:flutter/material.dart` for it — [RaaPodhamApp] and
/// `SettingsScreen` map it to `ThemeMode`/`Brightness` where each actually
/// needs one.
enum AppThemeMode { system, light, dark }

/// Persists the device's [AppThemeMode] across launches — the only class
/// that should import `package:shared_preferences`.
class ThemeModeRepository {
  ThemeModeRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _key = 'appThemeMode';

  /// Defaults to [AppThemeMode.light] — not [AppThemeMode.system] — until
  /// the user picks something in Settings, per product direction.
  Future<AppThemeMode> loadThemeMode() async {
    final raw = await _prefs.getString(_key);
    return AppThemeMode.values.asNameMap()[raw] ?? AppThemeMode.light;
  }

  Future<void> saveThemeMode(AppThemeMode mode) =>
      _prefs.setString(_key, mode.name);
}

@Riverpod(keepAlive: true)
ThemeModeRepository themeModeRepository(Ref ref) => ThemeModeRepository();
