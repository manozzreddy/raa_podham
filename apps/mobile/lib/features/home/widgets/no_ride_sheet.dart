import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../widgets/sheet_drag_handle.dart';
import '../../rides/models/ride.dart';
import 'home_sheet_chrome.dart';
import 'sheet_action_button.dart';
import 'upcoming_ride_card.dart';

/// The draggable sheet's content when the signed-in user isn't currently
/// in a ride: a persistent action row (Create / Join — always visible,
/// same pattern [RiderSheet] uses for its own actions), then either the
/// empty-state placeholder or a card per [upcomingRides] — still no
/// *past*-rides list, per product direction, but a scheduled ride the
/// user hosts or has joined is exactly what this sheet is for.
class NoRideSheet extends StatelessWidget {
  const NoRideSheet({
    super.key,
    required this.onCreateRide,
    required this.onJoinRide,
    required this.upcomingRides,
    required this.currentUserId,
    required this.onRideTap,
    required this.onStartRide,
  });

  final VoidCallback onCreateRide;
  final VoidCallback onJoinRide;

  /// Rides with [RideStatus.scheduled] the user hosts or has joined —
  /// already filtered by `HomeScreen`, which is the one watching the
  /// rides list.
  final List<Ride> upcomingRides;

  /// Null while auth state is still resolving — no card's Start Now
  /// button should render as host-enabled until this is known.
  final String? currentUserId;
  final ValueChanged<Ride> onRideTap;
  final ValueChanged<Ride> onStartRide;

  @override
  Widget build(BuildContext context) {
    final headerStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
              .copyWith(fontSize: 22, fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return HomeSheetContainer(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const SheetDragHandle(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [Text('Start riding', style: headerStyle)]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SheetActionButton(
                    icon: isCupertino ? CupertinoIcons.add_circled : Icons.add,
                    label: 'Create ride',
                    onPressed: onCreateRide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SheetActionButton(
                    icon: isCupertino ? CupertinoIcons.qrcode : Icons.group_add,
                    label: 'Join ride',
                    onPressed: onJoinRide,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: upcomingRides.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "You're not in a ride yet. Create one or join with an invite code.",
                      textAlign: TextAlign.center,
                      style: bodyStyle?.copyWith(
                        color: bodyStyle.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : _UpcomingRidesList(
                    rides: upcomingRides,
                    currentUserId: currentUserId,
                    onRideTap: onRideTap,
                    onStartRide: onStartRide,
                  ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRidesList extends StatelessWidget {
  const _UpcomingRidesList({
    required this.rides,
    required this.currentUserId,
    required this.onRideTap,
    required this.onStartRide,
  });

  final List<Ride> rides;
  final String? currentUserId;
  final ValueChanged<Ride> onRideTap;
  final ValueChanged<Ride> onStartRide;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelLarge;

    return ListView(
      primary: true,
      physics: homeSheetSnapPhysics,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text(
          'UPCOMING',
          style: labelStyle?.copyWith(
            color: labelStyle.color?.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        for (final ride in rides) ...[
          UpcomingRideCard(
            ride: ride,
            isHost: ride.hostId == currentUserId,
            onTap: () => onRideTap(ride),
            onStartRide: () => onStartRide(ride),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
