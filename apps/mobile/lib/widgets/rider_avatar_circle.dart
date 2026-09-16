import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A circular initials avatar in a flat brand color.
///
/// Used for the map overlay's own profile avatar, each rider's avatar in
/// `RiderAvatarChip` and the expanded rider list (both in the `home`
/// feature), and a past ride's member list (`rides` feature) — promoted
/// here once that second feature needed it too, per this codebase's
/// widget-sharing rule (`.agents/rules/architecture.md`).
/// [border]/[boxShadow] are null (no ring, no shadow) everywhere except
/// where a caller passes them explicitly — a flat list doesn't need
/// either, but an avatar floating directly over the map does, the same
/// way a marker's own rider dots get a white ring and shadow to read
/// clearly against whatever's underneath.
class RiderAvatarCircle extends StatelessWidget {
  const RiderAvatarCircle({
    super.key,
    required this.label,
    this.photoUrl,
    this.diameter = 40,
    this.background = AppColors.predawnIndigo,
    this.border,
    this.boxShadow,
  });

  final String label;

  /// The Google/Apple account photo, when the sign-in provider gave one.
  /// Falls back to [label]'s initial whenever this is null/empty, or if
  /// the image itself fails to load (stale URL, no network, ...).
  final String? photoUrl;
  final double diameter;
  final Color background;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  /// Space left between the border ring and the photo itself, so the
  /// ring reads as a halo around the image instead of an outline flush
  /// against its edge.
  static const double _photoRingGap = 3;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final resolvedBorder =
        border ??
        (hasPhoto ? Border.all(color: AppColors.sunriseAmber, width: 2) : null);
    // The border itself is painted starting from the container's outer
    // edge inward, so the photo needs to be inset by the border's own
    // width *plus* the gap — insetting by the gap alone (as this used
    // to do) let a border exactly as thick as the gap swallow it
    // completely, leaving no white visible at all. Every border used
    // here is `Border.all(...)`, so reading `.top.width` covers all
    // sides.
    final borderWidth = (resolvedBorder as Border?)?.top.width ?? 0;
    final photoDiameter = diameter - (borderWidth + _photoRingGap) * 2;
    // The gap between the photo and its ring is painted using this fill
    // — [background] is the *initial's* color (can be the same amber as
    // the ring itself), so reusing it here would make the gap invisible
    // against an amber ring.
    final fillColor = hasPhoto ? Colors.white : background;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: resolvedBorder,
        boxShadow: boxShadow,
      ),
      alignment: Alignment.center,
      child: !hasPhoto
          ? _InitialLabel(label: label, diameter: diameter)
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: photoDiameter,
                height: photoDiameter,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    _InitialLabel(label: label, diameter: diameter),
              ),
            ),
    );
  }
}

class _InitialLabel extends StatelessWidget {
  const _InitialLabel({required this.label, required this.diameter});

  final String label;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Text(
      initial,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: diameter * 0.4,
      ),
    );
  }
}

/// The small amber "host" badge overlaid on a rider's avatar.
class HostBadge extends StatelessWidget {
  const HostBadge({super.key, required this.ringColor});

  /// The color to ring the badge in, matching whatever it's sitting on
  /// (the sheet's background for a chip, a list tile's for a row).
  final Color ringColor;

  static const double diameter = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: AppColors.sunriseAmber,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Icon(
        isCupertino ? CupertinoIcons.star_fill : Icons.star,
        size: 9,
        color: Colors.white,
      ),
    );
  }
}
