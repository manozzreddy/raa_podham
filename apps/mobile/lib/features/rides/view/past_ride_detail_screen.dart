import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/providers.dart';
import '../../../theme/theme.dart';
import '../../../widgets/info_line.dart';
import '../../../widgets/rider_avatar_circle.dart';
import '../../../widgets/sheet_action_button.dart';
import '../../home/models/rider_profile.dart';
import '../data/ride_cover_photo_repository.dart';
import '../data/ride_members.dart';
import '../data/ride_repository.dart';
import '../models/ride.dart';
import '../view_model/rides_view_model.dart';

/// The full picture of a past ride — cover photo, timeline, destination,
/// notes, and everyone who rode — reached by tapping a row in
/// `PastRidesScreen`. A dedicated page, not a modal sheet: there's a lot
/// to show (the member list especially) and, unlike an upcoming ride's
/// card, nothing here is time-sensitive enough to justify a
/// lighter-weight sheet over a proper screen.
class PastRideDetailScreen extends ConsumerStatefulWidget {
  const PastRideDetailScreen({super.key, required this.ride});

  final Ride ride;

  @override
  ConsumerState<PastRideDetailScreen> createState() =>
      _PastRideDetailScreenState();
}

class _PastRideDetailScreenState extends ConsumerState<PastRideDetailScreen> {
  bool _isDeleting = false;

  Ride get ride => widget.ride;

  Future<void> _confirmAndDelete() async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(rideRepositoryProvider).deleteRide(ride.id);
      // Best-effort cleanup — the ride itself is already gone server-side
      // by this point, so a failure here just leaves an orphaned Storage
      // file rather than anything user-visible.
      final photoUrl = ride.coverPhotoUrl;
      if (photoUrl != null) {
        await ref
            .read(rideCoverPhotoRepositoryProvider)
            .deleteCoverPhoto(photoUrl);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't delete this ride. Try again.")),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(ridesViewModelProvider);
    context.pop();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    if (isCupertino) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete this ride?'),
          content: const Text(
            "This permanently deletes the ride, its notes and photo, and "
            "everyone's ride history for it. This can't be undone.",
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this ride?'),
        content: const Text(
          "This permanently deletes the ride, its notes and photo, and "
          "everyone's ride history for it. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle
              .copyWith(fontSize: 24)
        : Theme.of(context).textTheme.headlineSmall;
    final destination = ride.destination;
    final notes = ride.notes;
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final isHost = currentUserId != null && currentUserId == ride.hostId;

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CoverHero(ride: ride),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatusChip(),
                const SizedBox(height: 12),
                Text(ride.name, style: titleStyle),
                const SizedBox(height: 16),
                _TimelineSection(ride: ride),
                if (destination != null) ...[
                  const SizedBox(height: 24),
                  _DestinationSection(destination: destination),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _NotesSection(notes: notes),
                ],
                const SizedBox(height: 24),
                _MembersSection(rideId: ride.id, hostId: ride.hostId),
                if (isHost) ...[
                  const SizedBox(height: 32),
                  SheetActionButton(
                    icon: isCupertino
                        ? CupertinoIcons.delete
                        : Icons.delete_outline,
                    label: 'Delete ride',
                    isDestructive: true,
                    isLoading: _isDeleting,
                    onPressed: _confirmAndDelete,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Ride details')),
        child: SafeArea(child: content),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ride details')),
      body: SafeArea(child: content),
    );
  }
}

/// The cover photo (or a plain gradient fallback), full-bleed at the top
/// of the page — deliberately not the same widget as `UpcomingRideCard`'s
/// own banner: that one is compact, with the name/time overlaid on the
/// photo itself; this page has room to give the name its own heading
/// below instead, so the photo can just be a photo.
class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.ride});

  final Ride ride;

  static const double _height = 220;

  @override
  Widget build(BuildContext context) {
    final photoUrl = ride.coverPhotoUrl;

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: photoUrl != null
          ? CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const _GradientFallback(),
            )
          : const _GradientFallback(),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.asphaltInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'ENDED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.asphaltInk.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.labelLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: style?.copyWith(color: style.color?.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final scheduledAt = ride.scheduledAt;
    final endedAt = ride.endedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (scheduledAt != null) ...[
          InfoLine(
            icon: isCupertino ? CupertinoIcons.calendar : Icons.event_outlined,
            label: 'Was scheduled for ${formatScheduledTime(scheduledAt)}',
            style: captionStyle,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
        ],
        InfoLine(
          icon: isCupertino ? CupertinoIcons.add_circled : Icons.add_circle_outline,
          label: 'Created ${formatScheduledTime(ride.createdAt)}',
          style: captionStyle,
          maxLines: 2,
        ),
        if (endedAt != null) ...[
          const SizedBox(height: 6),
          InfoLine(
            icon: isCupertino ? CupertinoIcons.flag : Icons.flag_outlined,
            label: 'Ended ${formatScheduledTime(endedAt)}',
            style: captionStyle,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}

class _DestinationSection extends StatelessWidget {
  const _DestinationSection({required this.destination});

  final RideDestination destination;

  @override
  Widget build(BuildContext context) {
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Destination'),
        InfoLine(
          icon: isCupertino ? CupertinoIcons.location_solid : Icons.place,
          label: destination.name,
          style: captionStyle,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(destination.lat, destination.lng),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dynamicarraytech.raa_podham',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(destination.lat, destination.lng),
                        width: 36,
                        height: 36,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.place,
                          color: AppColors.roadFlareRed,
                          size: 36,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = bodyStyle?.color?.withValues(alpha: 0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Notes'),
        Text(notes, style: bodyStyle?.copyWith(color: mutedColor)),
      ],
    );
  }
}

class _MembersSection extends ConsumerWidget {
  const _MembersSection({required this.rideId, required this.hostId});

  final String rideId;
  final String hostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(rideMembersProvider(rideId));
    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          membersAsync.maybeWhen(
            data: (members) =>
                members.length == 1 ? 'Riders (1)' : 'Riders (${members.length})',
            orElse: () => 'Riders',
          ),
        ),
        membersAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: isCupertino
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          // Never fatal to the rest of the page — everything above
          // (photo, timeline, destination, notes) already stands on its
          // own without the member list.
          error: (error, stackTrace) => Text(
            "Couldn't load riders.",
            style: captionStyle?.copyWith(
              color: captionStyle.color?.withValues(alpha: 0.6),
            ),
          ),
          data: (members) {
            final sorted = [...members]
              ..sort((a, b) {
                if (a.riderId == hostId) return -1;
                if (b.riderId == hostId) return 1;
                return 0;
              });
            return Column(
              children: [
                for (final member in sorted)
                  _MemberRow(member: member, isHost: member.riderId == hostId),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isHost});

  final RiderProfile member;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final nameStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.textStyle
        : Theme.of(context).textTheme.bodyLarge;
    final sheetBackground = isCupertino
        ? CupertinoTheme.of(context).scaffoldBackgroundColor
        : Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                RiderAvatarCircle(
                  label: member.displayName,
                  photoUrl: member.photoUrl,
                  diameter: 44,
                  background: AppColors.riderFallbackColor(member.riderId),
                ),
                if (isHost)
                  Positioned(
                    left: -2,
                    top: -2,
                    child: HostBadge(ringColor: sheetBackground),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            ),
          ),
        ],
      ),
    );
  }
}
