import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/providers.dart';
import '../../../services/routes_repository.dart';
import '../../../theme/theme.dart';
import '../../../widgets/info_line.dart';
import '../../../widgets/rider_avatar_circle.dart';
import '../../../widgets/sheet_action_button.dart';
import '../../home/models/rider_profile.dart';
import '../data/ride_cover_photo_repository.dart';
import '../data/ride_members.dart';
import '../data/ride_repository.dart';
import '../data/ride_route_info.dart';
import '../models/ride.dart';
import '../view_model/rides_view_model.dart';

/// The full picture of a ride — cover photo, timeline, destination,
/// notes, and everyone in it — reached by tapping a row in
/// `PastRidesScreen` (an ended ride) or an `UpcomingRideCard` (a
/// scheduled one). A dedicated page, not a modal sheet: there's a lot to
/// show (the member list especially), and status-aware rather than two
/// separate screens since almost everything here (photo, timeline,
/// destination, notes, members) doesn't care whether the ride has
/// happened yet — only the status chip and the action row at the bottom
/// do. Never reached for an active ride — that one's live picture is
/// `RiderSheet`, on the map itself.
class RideDetailScreen extends ConsumerStatefulWidget {
  const RideDetailScreen({super.key, required this.ride});

  final Ride ride;

  @override
  ConsumerState<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends ConsumerState<RideDetailScreen> {
  bool _isDeleting = false;
  bool _isStarting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await _confirmDelete(context, widget.ride.status);
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(rideRepositoryProvider).deleteRide(widget.ride.id);
      // Best-effort cleanup — the ride itself is already gone server-side
      // by this point, so a failure here just leaves an orphaned Storage
      // file rather than anything user-visible.
      final photoUrl = widget.ride.coverPhotoUrl;
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

  Future<bool> _confirmDelete(BuildContext context, RideStatus status) async {
    // A scheduled ride never happened, so there's no "ride history" to
    // mention — just what joining riders lose by it disappearing.
    final message = status == RideStatus.scheduled
        ? "This permanently deletes the ride and removes it for everyone "
              "who joined. This can't be undone."
        : "This permanently deletes the ride, its notes and photo, and "
              "everyone's ride history for it. This can't be undone.";

    if (isCupertino) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete this ride?'),
          content: Text(message),
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
        content: Text(message),
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

  /// The host's "start now" action from the detail screen — same
  /// `RidesViewModel.startRideNow` call `HomeScreen._handleStartRide`
  /// makes for the same action from `UpcomingRideCard`, which already
  /// refreshes the rides list on success. Pops back to `HomeScreen` on
  /// success, which re-resolves to the map on its own.
  Future<void> _handleStartNow(Ride ride) async {
    setState(() => _isStarting = true);
    final succeeded = await ref
        .read(ridesViewModelProvider.notifier)
        .startRideNow(ride.id);
    if (!mounted) return;
    setState(() => _isStarting = false);
    if (succeeded) {
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't start the ride. Try again.")),
    );
  }

  Future<void> _shareInvite(Ride ride) async {
    await SharePlus.instance.share(
      ShareParams(
        text: buildInviteMessage(ride),
        subject: 'Join my ride on Raa Podham',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-resolved from the live rides list (falling back to the ride this
    // screen was opened with, while that's still loading) rather than
    // just `widget.ride` throughout — so Start now/Edit ride's
    // `ridesViewModelProvider` invalidation is reflected here immediately
    // on returning, instead of showing stale data until this screen is
    // reopened.
    final rides = ref.watch(ridesViewModelProvider).value;
    final ride =
        rides?.firstWhere(
          (candidate) => candidate.id == widget.ride.id,
          orElse: () => widget.ride,
        ) ??
        widget.ride;

    if (ride.status == RideStatus.active) {
      // Shouldn't normally happen (see this class's own doc comment) —
      // but clearing the scheduled time during an edit flips a ride
      // active while this screen is still open, and there's no correct
      // picture for this screen to show for that: bounce back to
      // HomeScreen (which pushed this screen in the first place, and is
      // still alive underneath, never disposed), where it re-resolves to
      // RiderSheet's own active-ride view. A single pop, not
      // context.go('/home') — go() replaces the whole stack, which tears
      // HomeScreen down and rebuilds it from scratch, cancelling
      // HomeViewModel's in-flight GPS/RTDB position reporting before it
      // ever completes and leaving every rider stuck at 0 until the next
      // cold start. Deliberately not rendered inline either (e.g. a
      // status label swap) — that would let this screen silently start
      // supporting a state its layout was never designed for.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return isCupertino
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final destination = ride.destination;
    final notes = ride.notes;
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final isHost = currentUserId != null && currentUserId == ride.hostId;
    final isUpcoming = ride.status == RideStatus.scheduled;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(status: ride.status),
          const SizedBox(height: 16),
          _TimelineSection(ride: ride),
          if (destination != null) ...[
            const SizedBox(height: 24),
            _DestinationSection(destination: destination),
          ],
          if (isUpcoming && destination != null) ...[
            const SizedBox(height: 16),
            _RouteInfoSection(ride: ride),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            _NotesSection(notes: notes),
          ],
          const SizedBox(height: 24),
          _MembersSection(rideId: ride.id, hostId: ride.hostId),
          const SizedBox(height: 32),
          _buildActionRow(context, ride, isHost),
        ],
      ),
    );

    final hasCoverPhoto = ride.coverPhotoUrl != null;

    if (isCupertino) {
      // CupertinoSliverNavigationBar has no photo-behind-large-title
      // support of its own — the photo, when there is one, sits as a
      // plain item below it instead.
      return CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(largeTitle: Text(ride.name)),
            if (hasCoverPhoto)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _CoverHero.height,
                  child: _CoverHero(ride: ride),
                ),
              ),
            SliverToBoxAdapter(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            if (hasCoverPhoto)
              SliverAppBar(
                expandedHeight: _CoverHero.height,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.predawnIndigo,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  // stretchModes defaults to zoomBackground already.
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 56,
                    bottom: 16,
                    end: 16,
                  ),
                  title: Text(
                    ride.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: _CoverHero(ride: ride),
                ),
              )
            else
              SliverAppBar(pinned: true, title: Text(ride.name)),
            SliverToBoxAdapter(child: body),
          ],
        ),
      ),
    );
  }

  /// Status+host aware — an ended ride only ever shows Delete (host-only,
  /// nothing at all otherwise); an upcoming one shows Start now/Edit
  /// ride/Invite for the host, or just Invite plus a waiting note for
  /// everyone else. The ride passed in is always one of the two once it
  /// reaches this screen (see [RideDetailScreen]'s own doc comment).
  Widget _buildActionRow(BuildContext context, Ride ride, bool isHost) {
    if (ride.status == RideStatus.ended) {
      if (!isHost) return const SizedBox.shrink();
      return SheetActionButton(
        icon: isCupertino ? CupertinoIcons.delete : Icons.delete_outline,
        label: 'Delete ride',
        isDestructive: true,
        isLoading: _isDeleting,
        onPressed: _confirmAndDelete,
      );
    }

    if (isHost) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetActionButton(
            icon: isCupertino
                ? CupertinoIcons.play_arrow_solid
                : Icons.play_arrow,
            label: 'Start now',
            isLoading: _isStarting,
            onPressed: () => _handleStartNow(ride),
          ),
          const SizedBox(height: 12),
          SheetActionButton(
            icon: isCupertino ? CupertinoIcons.pencil : Icons.edit_outlined,
            label: 'Edit ride',
            onPressed: () => context.push('/rides/edit', extra: ride),
          ),
          const SizedBox(height: 12),
          SheetActionButton(
            icon: isCupertino
                ? CupertinoIcons.person_add_solid
                : Icons.person_add_alt_1,
            label: 'Invite',
            onPressed: () => _shareInvite(ride),
          ),
          const SizedBox(height: 12),
          SheetActionButton(
            icon: isCupertino ? CupertinoIcons.delete : Icons.delete_outline,
            label: 'Delete ride',
            isDestructive: true,
            isLoading: _isDeleting,
            onPressed: _confirmAndDelete,
          ),
        ],
      );
    }

    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;
    final mutedColor = captionStyle?.color?.withValues(alpha: 0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isCupertino ? CupertinoIcons.hourglass : Icons.hourglass_empty,
              size: 16,
              color: mutedColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for the host to start this ride',
                style: captionStyle?.copyWith(color: mutedColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SheetActionButton(
          icon: isCupertino
              ? CupertinoIcons.person_add_solid
              : Icons.person_add_alt_1,
          label: 'Invite',
          onPressed: () => _shareInvite(ride),
        ),
      ],
    );
  }
}

/// The cover photo (or a plain gradient fallback), with a bottom scrim
/// for legible white text over it. Sized by its caller, not itself — on
/// Material it's `FlexibleSpaceBar.background` (sized to the animating
/// header); on Cupertino it's a plain, fixed-height ([height]) item.
class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.ride});

  final Ride ride;

  static const double height = 220;

  @override
  Widget build(BuildContext context) {
    final photoUrl = ride.coverPhotoUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        photoUrl != null
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const _GradientFallback(),
              )
            : const _GradientFallback(),
        // Legible white title/back button over any photo — same bottom
        // scrim `UpcomingRideCard`'s own cover banner uses.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black45],
              stops: [0.5, 1.0],
            ),
          ),
        ),
      ],
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
  const _StatusChip({required this.status});

  final RideStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status == RideStatus.scheduled ? 'UPCOMING' : 'ENDED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.asphaltInk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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
            label: ride.status == RideStatus.scheduled
                ? 'Scheduled for ${formatScheduledTime(scheduledAt)}'
                : 'Was scheduled for ${formatScheduledTime(scheduledAt)}',
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
                    userAgentPackageName: 'in.manojreddy.raa_podham',
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

/// The rider's own real-road distance/ETA to the destination — shown
/// only for an upcoming ride (see [RideDetailScreen.build]'s `isUpcoming`
/// guard), the same [rideRouteInfoProvider] the active ride's `RiderSheet`
/// draws its own live numbers from. Renders nothing while loading, on
/// error, or with no result (no position/no destination) — never fatal
/// to the rest of the page, same treatment [_MembersSection] gives its
/// own error case.
class _RouteInfoSection extends ConsumerWidget {
  const _RouteInfoSection({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(rideRouteInfoProvider(ride));
    final route = routeAsync.value;
    if (route == null) return const SizedBox.shrink();

    final captionStyle = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return InfoLine(
      icon: isCupertino ? CupertinoIcons.flag_fill : Icons.flag,
      label: _formatRouteInfo(route),
      style: captionStyle,
      maxLines: 1,
    );
  }

  String _formatRouteInfo(RouteInfo route) {
    final km = (route.distanceMeters / 1000).toStringAsFixed(1);
    final minutes = (route.durationSeconds / 60).round();
    return '$km km · ~$minutes min away';
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
