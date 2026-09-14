import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Raa Podham's [CupertinoThemeData], for the iOS-native widget tree.
///
/// Unlike [MaterialApp], [CupertinoApp] has no built-in `themeMode` /
/// `darkTheme` split — it takes one [CupertinoThemeData]. To still follow
/// the OS light/dark setting, build the theme with [themeFor] using the
/// current [Brightness] (e.g. `MediaQuery.platformBrightnessOf(context)`)
/// rather than reaching for [light] or [dark] directly.
abstract final class AppCupertinoTheme {
  /// Theme pinned to light brightness.
  static CupertinoThemeData get light => themeFor(Brightness.light);

  /// Theme pinned to dark brightness.
  static CupertinoThemeData get dark => themeFor(Brightness.dark);

  /// Builds a [CupertinoThemeData] matching [brightness].
  static CupertinoThemeData themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final groundColor = isDark
        ? AppColors.predawnIndigo
        : AppColors.firstLightCream;
    final textColor = isDark ? CupertinoColors.white : AppColors.asphaltInk;

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.sunriseAmber,
      primaryContrastingColor: AppColors.predawnIndigo,
      scaffoldBackgroundColor: groundColor,
      barBackgroundColor: groundColor,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.sunriseAmber,
        textStyle: GoogleFonts.manrope(fontSize: 16, color: textColor),
        actionTextStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.sunriseAmber,
        ),
        tabLabelTextStyle: GoogleFonts.manrope(fontSize: 10, color: textColor),
        navTitleTextStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        navLargeTitleTextStyle: GoogleFonts.manrope(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        navActionTextStyle: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.sunriseAmber,
        ),
        pickerTextStyle: GoogleFonts.manrope(fontSize: 21, color: textColor),
        dateTimePickerTextStyle: GoogleFonts.manrope(
          fontSize: 21,
          color: textColor,
        ),
      ),
    );
  }
}
