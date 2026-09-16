import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme.dart';
import '../../../widgets/app_error_screen.dart';
import '../models/ride.dart';
import '../view_model/rides_view_model.dart';

/// Every ride the signed-in user hosted or joined that's since ended.
/// Reachable from the app drawer, not `NoRideSheet` — unlike an upcoming
/// ride's card, nothing here is actionable (no Start now, no invite), so
/// it doesn't belong on the frequently-visited landing sheet alongside
/// Create/Join (see that sheet's own doc comment on staying minimal).
class PastRidesScreen extends ConsumerWidget {
  const PastRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(ridesViewModelProvider);

    return ridesAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, stackTrace) => AppErrorScreen(
        error: error,
        stackTrace: stackTrace,
        message: "Couldn't load your past rides.",
        onRetry: () => ref.invalidate(ridesViewModelProvider),
      ),
      data: (rides) {
        final pastRides = rides.where((ride) => ride.status == RideStatus.ended).toList()
          ..sort(
            (a, b) =>
                (b.endedAt ?? b.createdAt).compareTo(a.endedAt ?? a.createdAt),
          );
        return _PastRidesScaffold(pastRides: pastRides);
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final indicator = isCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Past rides')),
        child: Center(child: indicator),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Past rides')),
      body: Center(child: indicator),
    );
  }
}

class _PastRidesScaffold extends StatelessWidget {
  const _PastRidesScaffold({required this.pastRides});

  final List<Ride> pastRides;

  @override
  Widget build(BuildContext context) {
    final content = pastRides.isEmpty
        ? const _EmptyState()
        : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: pastRides.length,
            separatorBuilder: (context, index) => const SizedBox.shrink(),
            itemBuilder: (context, index) => _PastRideTile(ride: pastRides[index]),
          );

    if (isCupertino) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Past rides')),
        child: SafeArea(child: content),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Past rides')),
      body: content,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final style = isCupertino
        ? CupertinoTheme.of(context).textTheme.tabLabelTextStyle
        : Theme.of(context).textTheme.bodyMedium;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          "Rides you've hosted or joined will show up here once they end.",
          textAlign: TextAlign.center,
          style: style?.copyWith(color: style.color?.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

class _PastRideTile extends StatelessWidget {
  const _PastRideTile({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final destination = ride.destination;
    final subtitle = [
      if (destination != null) destination.name,
      formatPastDate(ride.endedAt ?? ride.createdAt),
    ].join(' · ');
    final leading = _PastRideThumbnail(photoUrl: ride.coverPhotoUrl);
    void onTap() => context.push('/rides/past/detail', extra: ride);

    if (isCupertino) {
      return CupertinoListTile(
        leading: leading,
        title: Text(ride.name),
        subtitle: Text(subtitle),
        trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: leading,
      title: Text(ride.name),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _PastRideThumbnail extends StatelessWidget {
  const _PastRideThumbnail({required this.photoUrl});

  final String? photoUrl;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const _FallbackThumbnail(),
              )
            : const _FallbackThumbnail(),
      ),
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.predawnIndigo.withValues(alpha: 0.08),
      child: Icon(
        isCupertino ? CupertinoIcons.time : Icons.history,
        color: AppColors.predawnIndigo.withValues(alpha: 0.5),
      ),
    );
  }
}
