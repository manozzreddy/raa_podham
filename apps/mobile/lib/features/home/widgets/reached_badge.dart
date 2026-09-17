import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// The small "reached destination" badge overlaid on a rider's avatar —
/// same shape/ring treatment as `HostBadge` (`lib/widgets/rider_avatar_circle.dart`),
/// just a different icon/color, so the two read as siblings wherever both
/// can appear on the same avatar.
class ReachedBadge extends StatelessWidget {
  const ReachedBadge({super.key, required this.ringColor});

  /// The color to ring the badge in, matching whatever it's sitting on —
  /// see `HostBadge.ringColor`.
  final Color ringColor;

  static const double diameter = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: AppColors.predawnIndigo,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Icon(
        isCupertino ? CupertinoIcons.flag_fill : Icons.flag,
        size: 9,
        color: Colors.white,
      ),
    );
  }
}

/// The "reached destination" text pill for `RiderInfoSheet`'s name row —
/// same shape as that file's private `_HostChip`, just worded/colored
/// differently, so the two read as siblings when both apply to one rider.
class ReachedChip extends StatelessWidget {
  const ReachedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.predawnIndigo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'REACHED',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
