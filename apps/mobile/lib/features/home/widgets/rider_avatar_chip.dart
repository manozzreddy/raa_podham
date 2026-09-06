import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// A circular initials avatar in a flat brand color.
///
/// Used both for the search bar's own profile avatar and for each rider's
/// avatar in [RiderAvatarChip] and the expanded rider list.
class RiderAvatarCircle extends StatelessWidget {
  const RiderAvatarCircle({
    super.key,
    required this.label,
    this.diameter = 40,
    this.background = AppColors.predawnIndigo,
  });

  final String label;
  final double diameter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: diameter * 0.4,
        ),
      ),
    );
  }
}

/// Collapsed-sheet chip: a rider's avatar with a status dot bottom-right,
/// and a distance label underneath (e.g. "You", "0.6 km").
class RiderAvatarChip extends StatelessWidget {
  const RiderAvatarChip({
    super.key,
    required this.displayName,
    required this.distanceLabel,
    required this.isOnline,
    this.isSelf = false,
  });

  final String displayName;
  final String distanceLabel;
  final bool isOnline;
  final bool isSelf;

  static const double _avatarDiameter = 48;
  static const double _statusDotDiameter = 14;

  @override
  Widget build(BuildContext context) {
    final sheetBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelSmall;

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _avatarDiameter,
            height: _avatarDiameter,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RiderAvatarCircle(
                  label: displayName,
                  diameter: _avatarDiameter,
                  background: isSelf ? AppColors.sunriseAmber : AppColors.predawnIndigo,
                ),
                if (isOnline)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: _statusDotDiameter,
                      height: _statusDotDiameter,
                      decoration: BoxDecoration(
                        color: AppColors.sunRimGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: sheetBackground, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            distanceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: captionStyle?.copyWith(color: captionStyle.color?.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
