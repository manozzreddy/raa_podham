import 'dart:async';

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/providers.dart';
import '../../rides/data/ride_repository.dart';
import '../../rides/models/ride.dart';
import '../data/device_location.dart';
import '../data/riders_for_ride.dart';
import '../models/rider.dart';

part 'home_view_model.g.dart';

/// Fallback map center, used until the device's own location resolves (or
/// if location permission/services aren't available): central Hyderabad.
const LatLng fallbackSelfLocation = LatLng(17.3850, 78.4867);

/// Everything the home screen needs to render for one ride.
class HomeUiState {
  const HomeUiState({
    required this.rideId,
    required this.rideName,
    required this.isHost,
    required this.riders,
    required this.autoFitBounds,
    required this.selfLocation,
    required this.isFollowingUser,
  });

  final String rideId;
  final String rideName;
  final bool isHost;

  /// Sorted by distance from self, "You" first.
  final List<RiderVm> riders;

  /// Bounds around every rider's last known position, for the map's
  /// initial camera fit. Null until at least one rider's position has
  /// arrived.
  final LatLngBounds? autoFitBounds;

  /// The device's own last known position and whether the map camera is
  /// still following it. Map-camera-follow mechanics predate the settled
  /// rider-sheet architecture and aren't part of what it redesigned, so
  /// they stay here rather than moving into the View.
  final LatLng selfLocation;
  final bool isFollowingUser;
}

/// A group member ready for the rider sheet: no coordinates (the map reads
/// those straight from [ridersForRideProvider] instead), just what the
/// sheet's chips/rows need to render.
class RiderVm {
  const RiderVm({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.distanceLabel,
    required this.isOnline,
    required this.isSelf,
    required this.isHost,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;

  /// "You" for self, "0.6 km" once the device's own location has resolved,
  /// "—" before then (a distance from the fallback location would be
  /// meaningless).
  final String distanceLabel;
  final bool isOnline;
  final bool isSelf;
  final bool isHost;
}

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// map-follow state. Widget-level concerns — the `MapController`, the
/// rider sheet's own drag mechanics — stay in the View (`HomeScreen`) and
/// react to this state rather than living here.
@riverpod
class HomeViewModel extends _$HomeViewModel {
  bool _hasStartedLocationResolution = false;
  bool _hasResolvedSelfLocation = false;
  LatLng _selfLocation = fallbackSelfLocation;
  bool _isFollowingUser = true;
  List<Rider> _lastRiders = const [];
  late Ride _ride;

  @override
  Future<HomeUiState> build(Ride ride) async {
    _ride = ride;

    if (!_hasStartedLocationResolution) {
      _hasStartedLocationResolution = true;
      unawaited(_resolveInitialLocation());
    }

    final riders = await ref.watch(ridersForRideProvider(ride.id).future);
    _lastRiders = riders;
    return _currentState(riders);
  }

  /// Re-acquires the device's location, recenters on it, and marks the
  /// map as following the user again.
  Future<void> recenter() async {
    final position = await acquireCurrentPosition();
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _hasResolvedSelfLocation = true;
    _isFollowingUser = true;
    _publish();
  }

  /// The user panned/zoomed the map by hand, so the recenter button
  /// should stop reading as "active" until they tap it again.
  void onMapPanned() {
    if (!_isFollowingUser) return;
    _isFollowingUser = false;
    _publish();
  }

  /// Shares the ride's invite link through the platform share sheet —
  /// [buildInviteMessage] is shared with `ShareInviteScreen` so wording
  /// is identical across both entry points.
  Future<void> inviteMore() async {
    await SharePlus.instance.share(
      ShareParams(
        text: buildInviteMessage(_ride),
        subject: 'Join my ride on Raa Podham',
      ),
    );
  }

  /// Ends the ride for everyone if the current user is the host, otherwise
  /// just removes them from it.
  Future<void> endOrLeaveRide() async {
    final repository = ref.read(rideRepositoryProvider);
    if (_isHost) {
      await repository.endRide(_ride.id);
    } else {
      await repository.leaveRide(_ride.id);
    }
  }

  bool get _isHost =>
      _ride.hostId == ref.read(firebaseAuthServiceProvider).currentUser?.uid;

  /// The given rider's last known location, for the View to recenter the
  /// map on when their sheet row is tapped — read from [_lastRiders]
  /// rather than added to [RiderVm], which deliberately carries no
  /// coordinates of its own (see its own doc comment).
  LatLng? locationOf(String riderId) {
    for (final rider in _lastRiders) {
      if (rider.riderId == riderId) return rider.location;
    }
    return null;
  }

  Future<void> _resolveInitialLocation() async {
    final position = await acquireCurrentPosition();
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _hasResolvedSelfLocation = true;
    _publish();
  }

  /// Re-publishes [state] using the riders from the last successful
  /// [build], since a plain state-mutation method (unlike [build]) has no
  /// fresh value from [ridersForRideProvider] to work with.
  void _publish() {
    state = AsyncData(_currentState(_lastRiders));
  }

  HomeUiState _currentState(List<Rider> riders) {
    final sortedRiders = _sortedByDistance(riders);
    return HomeUiState(
      rideId: _ride.id,
      rideName: _ride.name,
      isHost: _isHost,
      riders: sortedRiders.map(_toRiderVm).toList(growable: false),
      autoFitBounds: riders.isEmpty
          ? null
          : LatLngBounds.fromPoints(
              riders.map((rider) => rider.location).toList(),
            ),
      selfLocation: _selfLocation,
      isFollowingUser: _isFollowingUser,
    );
  }

  /// Self first, then everyone else nearest-first.
  List<Rider> _sortedByDistance(List<Rider> riders) {
    final others = riders.where((rider) => !rider.isSelf).toList()
      ..sort((a, b) => _distanceFromSelf(a).compareTo(_distanceFromSelf(b)));
    final self = riders.where((rider) => rider.isSelf);
    return [...self, ...others];
  }

  double _distanceFromSelf(Rider rider) {
    return Geolocator.distanceBetween(
      _selfLocation.latitude,
      _selfLocation.longitude,
      rider.location.latitude,
      rider.location.longitude,
    );
  }

  RiderVm _toRiderVm(Rider rider) {
    final distanceLabel = rider.isSelf
        ? 'You'
        : (_hasResolvedSelfLocation
              ? _formatDistance(_distanceFromSelf(rider))
              : '—');
    // Only self has a photo to show at all right now — other riders'
    // Google/Apple photos aren't plumbed through Firestore membership
    // yet, so they fall back to their initial like before.
    final photoUrl = rider.isSelf
        ? ref.read(firebaseAuthServiceProvider).currentUser?.photoURL
        : null;
    return RiderVm(
      uid: rider.riderId,
      displayName: rider.isSelf ? 'You' : rider.displayName,
      photoUrl: photoUrl,
      distanceLabel: distanceLabel,
      isOnline: rider.isOnline,
      isSelf: rider.isSelf,
      isHost: rider.riderId == _ride.hostId,
    );
  }

  String _formatDistance(double meters) =>
      '${(meters / 1000).toStringAsFixed(1)} km';
}
