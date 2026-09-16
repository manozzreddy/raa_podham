import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/rider_avatar_circle.dart';

export '../../../widgets/rider_avatar_circle.dart';

/// Collapsed-sheet chip: a rider's avatar with a status dot bottom-right
/// (and a host badge top-left, if they're hosting), a distance label
/// underneath (e.g. "You", "0.6 km") — tappable to recenter the map on
/// them, when [onTap] is given.
class RiderAvatarChip extends StatelessWidget {
  const RiderAvatarChip({
    super.key,
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.distanceLabel,
    required this.isOnline,
    this.isSelf = false,
    this.isHost = false,
    this.onTap,
  });

  /// Only used to pick a stable fallback avatar color (see
  /// `AppColors.riderFallbackColor`) — not otherwise needed here, tap
  /// handling is the caller's own `onTap` closure.
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String distanceLabel;
  final bool isOnline;
  final bool isSelf;
  final bool isHost;
  final VoidCallback? onTap;

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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
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
                    photoUrl: photoUrl,
                    diameter: _avatarDiameter,
                    background: isSelf
                        ? AppColors.sunriseAmber
                        : AppColors.riderFallbackColor(uid),
                  ),
                  if (isHost)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: HostBadge(ringColor: sheetBackground),
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
              style: captionStyle?.copyWith(
                color: captionStyle.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
