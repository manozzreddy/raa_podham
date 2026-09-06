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

  /// Light ground color.
  static const Color firstLightCream = Color(0xFFFFF7EE);

  /// Body text color on light backgrounds.
  static const Color asphaltInk = Color(0xFF3D4759);

  /// Divider color in light mode.
  static const Color hairline = Color(0xFFE8DFD3);
}
