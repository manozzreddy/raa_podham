import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../rides/models/ride.dart';

/// One scheduled ride, shown in [NoRideSheet]'s upcoming-rides list: a
/// cover-photo banner (or a plain gradient one, if the host didn't add a
/// photo) with the name/time overlaid, the destination underneath, and a
/// host-only "Start now" action — tapping the card itself (anywhere but
/// that button) opens `UpcomingRideDetailSheet` for the full picture.
class UpcomingRideCard extends StatelessWidget {
  const UpcomingRideCard({
    super.key,
    required this.ride,
    required this.isHost,
    required this.onTap,
    required this.onStartRide,
  });

  final Ride ride;
  final bool isHost;
  final VoidCallback onTap;
  final VoidCallback onStartRide;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = bodyStyle?.color?.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: isCupertino
            ? CupertinoTheme.of(context).scaffoldBackgroundColor
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CoverBanner(ride: ride),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    if (ride.destination != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              isCupertino
                                  ? CupertinoIcons.location_solid
                                  : Icons.place,
                              size: 14,
                              color: AppColors.roadFlareRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ride.destination!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: bodyStyle?.copyWith(color: mutedColor),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    if (isHost)
                      _StartNowButton(onPressed: onStartRide)
                    else
                      Text(
                        'Waiting for host',
                        style: bodyStyle?.copyWith(
                          color: mutedColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo (or a plain gradient fallback) with the ride's name and
/// scheduled time overlaid at the bottom, always legible over either.
class _CoverBanner extends StatelessWidget {
  const _CoverBanner({required this.ride});

  final Ride ride;

  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    final photoUrl = ride.coverPhotoUrl;
    final scheduledAt = ride.scheduledAt;

    return SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl != null)
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const _GradientFallback(),
            )
          else
            const _GradientFallback(),
          // Always drawn, over a photo or the fallback alike — otherwise
          // white overlay text is unreadable against a bright photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ride.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (scheduledAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatScheduledTime(scheduledAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.predawnIndigo, AppColors.sunriseAmber],
        ),
      ),
    );
  }
}

class _StartNowButton extends StatelessWidget {
  const _StartNowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        color: AppColors.sunriseAmber,
        borderRadius: BorderRadius.circular(20),
        onPressed: onPressed,
        child: const Text(
          'Start now',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sunriseAmber,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        'Start now',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
