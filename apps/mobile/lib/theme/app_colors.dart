import 'package:flutter/widgets.dart';

/// Fixed brand color constants for Raa Podham.
///
/// These are literal brand values, not derived from a seed or from one
/// another — treat this as the single source of truth for brand color and
/// reference these constants rather than re-typing hex values elsewhere.
abstract final class AppColors {
  /// Primary brand color; also the Material seed color.
  static const Color sunriseAmber = Color(0xFFFF7A33);

  /// Secondary accent; used for the live-position indicator on the map.
  static const Color sunRimGold = Color(0xFFFFB648);

  /// Dark ground color / icon backing plate.
  static const Color predawnIndigo = Color(0xFF1C2541);

  /// The ride destination pin — the classic "map marker" red, distinct
  /// from both destructive-action red (Colors.red/
  /// CupertinoColors.destructiveRed, used for Remove/End) and the rider
  /// palette's own brick red below, so the pin never gets read as either
  /// of those.
  static const Color roadFlareRed = Color(0xFFE0483F);

  /// Light ground color.
  static const Color firstLightCream = Color(0xFFFFF7EE);

  /// Body text color on light backgrounds.
  static const Color asphaltInk = Color(0xFF3D4759);

  /// Divider color in light mode.
  static const Color hairline = Color(0xFFE8DFD3);

  /// Rider-avatar background colors for anyone but self (self always
  /// gets [sunriseAmber], everywhere) — deliberately not reusing that
  /// color here so self stays visually unique among the group.
  static const List<Color> _riderPalette = [
    predawnIndigo,
    Color(0xFF2E7D6B), // teal
    Color(0xFF6B4C9A), // violet
    Color(0xFFB5484F), // brick red
    Color(0xFF3D6EA5), // steel blue
  ];

  /// A stable background color for a rider's avatar, picked
  /// deterministically from [uid] so the same rider always gets the same
  /// color everywhere they appear (map marker, sheet chip, detail row),
  /// without anything needing to coordinate assignment.
  static Color riderFallbackColor(String uid) =>
      _riderPalette[uid.hashCode.abs() % _riderPalette.length];
}
