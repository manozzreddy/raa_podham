import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

/// Raa Podham's Material 3 [ThemeData], for the Android/web widget tree.
///
/// Both [light] and [dark] derive their [ColorScheme] from
/// [AppColors.sunriseAmber] via [ColorScheme.fromSeed], then pin the ground
/// and accent colors to the literal brand values instead of the tones
/// [ColorScheme.fromSeed] would otherwise generate for them.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sunriseAmber,
      brightness: Brightness.light,
    ).copyWith(
      secondary: AppColors.sunRimGold,
      surface: AppColors.firstLightCream,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.firstLightCream,
      textTheme: AppTextTheme.light,
      dividerColor: AppColors.hairline,
      dividerTheme: const DividerThemeData(color: AppColors.hairline),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sunriseAmber,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: AppColors.sunRimGold,
      surface: AppColors.predawnIndigo,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.predawnIndigo,
      textTheme: AppTextTheme.dark,
    );
  }
}
