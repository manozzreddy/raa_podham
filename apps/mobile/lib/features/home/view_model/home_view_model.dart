import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/providers.dart';
import '../../rides/data/ride_repository.dart';
import '../../rides/models/ride.dart';
import '../data/device_location.dart';
import '../data/position_repository.dart';
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
    required this.destination,
    required this.autoFitBounds,
    required this.selfLocation,
    required this.isFollowingUser,
    required this.isLocationUnavailable,
  });

  final String rideId;
  final String rideName;
  final bool isHost;

  /// Sorted by distance from self, "You" first.
  final List<RiderVm> riders;

  /// The ride's destination pin, if one was set when it was created.
  final RideDestination? destination;

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

  /// True when this device's own location can't currently be reported —
  /// permission denied or the location-services toggle off — meaning
  /// this rider is invisible to the rest of the group right now. The
  /// View shows a banner prompting them to fix it when this is true.
  final bool isLocationUnavailable;
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
  bool _hasStartedPositionReporting = false;
  bool _hasResolvedSelfLocation = false;
  LatLng _selfLocation = fallbackSelfLocation;
  bool _isFollowingUser = true;
  bool _isLocationUnavailable = false;
  List<Rider> _lastRiders = const [];
  StreamSubscription<Position>? _positionReportSubscription;
  StreamSubscription<bool>? _locationServiceSubscription;
  late Ride _ride;

  @override
  Future<HomeUiState> build(Ride ride) async {
    _ride = ride;

    if (!_hasStartedLocationResolution) {
      _hasStartedLocationResolution = true;
      unawaited(_resolveInitialLocation());
    }
    if (!_hasStartedPositionReporting) {
      _hasStartedPositionReporting = true;
      _startReportingPosition();
      unawaited(_checkInitialLocationAvailability());
      _locationServiceSubscription = watchLocationServicesEnabled().listen((
        enabled,
      ) {
        _isLocationUnavailable = !enabled;
        _publish();
      });
      // Only stops the device's own streams on dispose — the RTDB entry
      // itself is left alone here, since disposal (e.g. navigating away
      // momentarily) isn't the same as actually leaving the ride.
      ref.onDispose(() {
        _positionReportSubscription?.cancel();
        _locationServiceSubscription?.cancel();
      });
    }

    final riders = await ref.watch(ridersForRideProvider(ride.id).future);
    _lastRiders = riders;
    return _currentState(riders);
  }

  void _startReportingPosition() {
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    final positions = ref.read(positionRepositoryProvider);
    debugPrint('position stream started for ride ${_ride.id}, uid $uid');
    _positionReportSubscription = watchCurrentPosition().listen(
      (position) {
        debugPrint(
          'reportPosition: ride ${_ride.id} uid $uid '
          '(${position.latitude}, ${position.longitude})',
        );
        // Each emission fires its own write; a rejected/failed one must
        // not take down this subscription (an uncaught Future error here
        // would otherwise propagate to the zone) or silently vanish — a
        // rider whose writes are failing shows up as "never has a
        // marker," with nothing else pointing at why, unless logged.
        unawaited(
          positions
              .reportPosition(
                rideId: _ride.id,
                uid: uid,
                lat: position.latitude,
                lng: position.longitude,
              )
              .catchError((Object error, StackTrace stackTrace) {
                debugPrint(
                  'reportPosition failed for ride ${_ride.id}: $error',
                );
              }),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        // watchCurrentPosition's own try/catch swallows setup failures
        // (permission denied, services off) by design — but that means
        // a genuinely broken stream (one that emits an error instead of
        // just completing) would otherwise vanish here too.
        debugPrint('position stream errored for ride ${_ride.id}: $error');
      },
    );
  }

  Future<void> _checkInitialLocationAvailability() async {
    final available = await isLocationAvailable();
    _isLocationUnavailable = !available;
    _publish();
  }

  /// Opens the device's location settings — the rider-invisible banner's
  /// call to action. [watchLocationServicesEnabled] picks up the change
  /// live if they actually turn it on, no restart or manual re-check
  /// needed.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

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
    // Ending already wipes the whole rides/{id} RTDB subtree server-side
    // (RTDBPresenceRepository.ClearRide), so this is only load-bearing for
    // the leave case — but harmless (and one fewer thing to keep in sync)
    // to always do it here regardless of which branch ran.
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid != null) {
      await ref
          .read(positionRepositoryProvider)
          .clearPosition(rideId: _ride.id, uid: uid);
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
    final destination = _ride.destination;
    final boundsPoints = [
      ...riders.map((rider) => rider.location),
      if (destination != null) LatLng(destination.lat, destination.lng),
    ];
    return HomeUiState(
      rideId: _ride.id,
      rideName: _ride.name,
      isHost: _isHost,
      riders: sortedRiders.map(_toRiderVm).toList(growable: false),
      destination: destination,
      // A single point makes a zero-area "bounds" — flutter_map's camera
      // fit computes an invalid (NaN/Infinity) zoom trying to fit one,
      // which then corrupts the shared MapController's state for the
      // rest of the session. Fitting only ever makes sense for 2+ points
      // anyway; with fewer, initialCenter already puts the camera
      // somewhere reasonable, so there's nothing lost by skipping it.
      autoFitBounds: boundsPoints.length < 2
          ? null
          : LatLngBounds.fromPoints(boundsPoints),
      selfLocation: _selfLocation,
      isFollowingUser: _isFollowingUser,
      isLocationUnavailable: _isLocationUnavailable,
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
