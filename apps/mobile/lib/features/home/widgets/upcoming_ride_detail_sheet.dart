import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/info_line.dart';
import '../../../widgets/sheet_drag_handle.dart';
import '../../rides/models/ride.dart';
import 'sheet_action_button.dart';

/// The "quick look" modal opened from an upcoming ride's card — the full
/// picture (notes, larger photo) that doesn't fit on the card itself, plus
/// the host's Start now action. Presented via `showModalBottomSheet`, same
/// as `RiderInfoSheet`.
class UpcomingRideDetailSheet extends StatelessWidget {
  const UpcomingRideDetailSheet({
    super.key,
    required this.ride,
    required this.isHost,
    required this.onStartRide,
    required this.onInviteMore,
  });

  final Ride ride;
  final bool isHost;
  final VoidCallback onStartRide;
  final VoidCallback onInviteMore;

  @override
  Widget build(BuildContext context) {
    final titleStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
              .copyWith(fontSize: 20)
        : Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyMedium;
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = captionStyle?.color?.withValues(alpha: 0.7);
    final photoUrl = ride.coverPhotoUrl;
    final scheduledAt = ride.scheduledAt;
    final destination = ride.destination;
    final notes = ride.notes;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: SheetDragHandle()),
              const SizedBox(height: 16),
              if (photoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(ride.name, style: titleStyle),
              const SizedBox(height: 10),
              if (scheduledAt != null) ...[
                InfoLine(
                  icon: isCupertino ? CupertinoIcons.clock : Icons.schedule,
                  label: formatScheduledTime(scheduledAt),
                  style: captionStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
              ],
              if (destination != null) ...[
                InfoLine(
                  icon: isCupertino
                      ? CupertinoIcons.location_solid
                      : Icons.place,
                  label: destination.name,
                  style: captionStyle,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(notes, style: bodyStyle?.copyWith(color: mutedColor)),
              ],
              const SizedBox(height: 20),
              if (isHost)
                SheetActionButton(
                  icon: isCupertino
                      ? CupertinoIcons.play_arrow_solid
                      : Icons.play_arrow,
                  label: 'Start now',
                  onPressed: () {
                    Navigator.of(context).pop();
                    onStartRide();
                  },
                )
              else
                Row(
                  children: [
                    Icon(
                      isCupertino
                          ? CupertinoIcons.hourglass
                          : Icons.hourglass_empty,
                      size: 16,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for the host to start this ride',
                      style: captionStyle?.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SheetActionButton(
                icon: isCupertino
                    ? CupertinoIcons.person_add_solid
                    : Icons.person_add_alt_1,
                label: 'Invite',
                onPressed: () {
                  Navigator.of(context).pop();
                  onInviteMore();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
