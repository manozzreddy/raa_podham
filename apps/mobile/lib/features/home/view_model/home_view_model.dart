import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/permission_service.dart';
import '../../../services/providers.dart';
import '../../../services/routes_repository.dart';
import '../../rides/data/ride_repository.dart';
import '../../rides/models/ride.dart';
import '../data/device_location.dart';
import '../data/position_repository.dart';
import '../data/riders_for_ride.dart';
import '../models/destination_proximity.dart';
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
    required this.showBackgroundSharingPrompt,
    required this.showReachedDestinationPrompt,
    required this.isSharingPaused,
    required this.routePolyline,
    required this.routeSummary,
    required this.selectedRiderUid,
    required this.infoRiderUid,
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

  /// True while the background-sharing rationale (background location,
  /// the foreground-service notification, battery-optimization
  /// exemption) is waiting on the rider's Allow/Not now — see
  /// [HomeViewModel.allowBackgroundSharing]/[skipBackgroundSharing]. The
  /// View shows that explainer screen in place of the map while this is
  /// true, exactly once per ride (it never flips back to true once
  /// resolved).
  final bool showBackgroundSharingPrompt;

  /// True exactly once, the moment this device's own live position first
  /// lands within [reachedDestinationRadiusMeters] of the ride's
  /// destination — see [HomeViewModel.dismissReachedDestinationPrompt].
  /// The View shows a confirm dialog offering to stop sharing while this
  /// is true, then dismisses it; it never re-arms for the rest of the
  /// ride, even if the rider leaves the radius and comes back.
  final bool showReachedDestinationPrompt;

  /// True once this device has stopped reporting its own position by
  /// choice (see [HomeViewModel.stopSharingLocation]), as opposed to
  /// [isLocationUnavailable]'s permission/services-off case. The View
  /// shows a banner with a way back in ([HomeViewModel.resumeSharingLocation])
  /// while this is true.
  final bool isSharingPaused;

  /// The route from self to the destination, decoded and ready to draw
  /// — empty until it resolves (no destination, self location not
  /// known yet, or the Routes API call failed). A failure here is never
  /// fatal to the rest of the screen: the destination pin and straight
  /// line distance already work without it.
  final List<LatLng> routePolyline;

  /// E.g. "12.3 km from start" for the same route — distance only, no
  /// duration, and labeled "from start" since it's a one-time snapshot
  /// from when the ride began, not a live-updating ETA. Null under the
  /// same conditions [routePolyline] is empty.
  final String? routeSummary;

  /// The rider whose name label is showing above their marker, if any —
  /// toggled by tapping a marker, a collapsed chip, or an expanded row.
  /// Independent of [infoRiderUid]: opening the info modal from a sheet
  /// row's ⓘ shouldn't also yank the map's selection over to them.
  final String? selectedRiderUid;

  /// The rider the info modal is currently open for, if any.
  final String? infoRiderUid;
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
    required this.hasReachedDestination,
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

  /// Whether this rider's current position is within
  /// [reachedDestinationRadiusMeters] of the ride's destination — false
  /// whenever the ride has no destination set. Purely geometric and
  /// recomputed live, same as [distanceLabel]; not the same thing as
  /// [HomeUiState.showReachedDestinationPrompt], which only ever applies
  /// to self and fires once.
  final bool hasReachedDestination;
}

/// Everything the Rider Info modal needs for one rider — resolved on
/// demand (see [HomeViewModel.riderInfoFor]) rather than carried on every
/// [RiderVm], since it needs coordinates [RiderVm] deliberately doesn't
/// have (the map already reads those straight from the live riders
/// stream instead).
class RiderInfoDetails {
  const RiderInfoDetails({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.isHost,
    required this.isOnline,
    required this.lastUpdatedLabel,
    required this.distanceFromSelfLabel,
    required this.distanceToDestinationLabel,
    required this.relativeToSelfLabel,
    required this.canNavigate,
    required this.canRemove,
    required this.isSelf,
    required this.hasReachedDestination,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final bool isHost;
  final bool isOnline;
  final bool isSelf;

  /// See [RiderVm.hasReachedDestination] — same computation, just also
  /// exposed here for the Rider Info modal's name-row chip.
  final bool hasReachedDestination;

  /// "Online" or e.g. "Last seen 3m ago".
  final String lastUpdatedLabel;

  /// E.g. "0.6 km away from you" — real road distance from you to this
  /// rider (Routes API, TWO_WHEELER), worded explicitly since "0.6 km
  /// away" alone doesn't say away from whom. Falls back to the same
  /// straight-line figure the sheet row shows, marked "(approx.)", if
  /// the API call itself fails.
  final String distanceFromSelfLabel;

  /// E.g. "2.1 km from destination" — real road distance (Routes API),
  /// null if the ride has no destination set.
  final String? distanceToDestinationLabel;

  /// E.g. "1.2 km ahead of you" / "0.4 km behind you" — comparing this
  /// rider's road distance to the destination against your own (reusing
  /// the route already computed once at ride start, not a fresh call).
  /// Null under the same condition [distanceToDestinationLabel] is.
  final String? relativeToSelfLabel;

  /// Whether Directions/Center-map have a real position to act on.
  final bool canNavigate;

  /// Whether the viewer can remove this rider — host only, and never
  /// for the host's own row (that's what End ride is for).
  final bool canRemove;
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
  bool _hasRequestedRoute = false;
  LatLng _selfLocation = fallbackSelfLocation;
  bool _isFollowingUser = true;
  bool _isLocationUnavailable = false;
  bool _showBackgroundSharingPrompt = false;
  bool _hasShownReachedPrompt = false;
  bool _showReachedDestinationPrompt = false;
  bool _isSharingPaused = false;
  RouteInfo? _route;
  List<Rider> _lastRiders = const [];
  String? _selectedRiderUid;
  String? _infoRiderUid;
  StreamSubscription<Position>? _positionReportSubscription;
  StreamSubscription<bool>? _locationServiceSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _staleRiderRecheckTimer;
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
      unawaited(_resolvePositionReporting());
      _armDisconnectCleanup();
      unawaited(_checkInitialLocationAvailability());
      _locationServiceSubscription = watchLocationServicesEnabled().listen((
        enabled,
      ) {
        _isLocationUnavailable = !enabled;
        _publish();
      });
      // Riders don't need a fresh position to go from "online" to "stale
      // and offline" — pure time passing is what does it (see
      // staleRiderThreshold) — so this re-derives isOnline on a timer
      // instead of only whenever someone's data happens to change.
      _staleRiderRecheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _publish(),
      );
      // Only stops the device's own streams/timers on dispose — the RTDB
      // entry itself is left alone here, since disposal (e.g. navigating
      // away momentarily) isn't the same as actually leaving the ride.
      ref.onDispose(() {
        _positionReportSubscription?.cancel();
        _locationServiceSubscription?.cancel();
        _connectionSubscription?.cancel();
        _staleRiderRecheckTimer?.cancel();
      });
    }

    final riders = await ref.watch(ridersForRideProvider(ride.id).future);
    _lastRiders = riders;
    return _currentState(riders);
  }

  /// Starts reporting immediately if background-sharing permissions are
  /// already settled from an earlier ride, otherwise shows the
  /// explainer first (via [showBackgroundSharingPrompt] in
  /// [HomeUiState]) and waits for [allowBackgroundSharing] or
  /// [skipBackgroundSharing] to actually start it.
  Future<void> _resolvePositionReporting() async {
    final isSatisfied = await ref
        .read(permissionServiceProvider)
        .isBackgroundSharingSatisfied();
    // Guards every method below with an async gap before it touches
    // `ref`/`_publish()` again — the ride could have ended (or this
    // screen been navigated away from) while the await above was
    // pending, disposing this auto-dispose provider, and touching `ref`
    // after that throws UnmountedRefException.
    if (!ref.mounted) return;
    if (isSatisfied) {
      _startReportingPosition();
      return;
    }
    _showBackgroundSharingPrompt = true;
    _publish();
  }

  /// The background-sharing explainer's Allow action: requests
  /// background location, the foreground-service notification, and the
  /// battery-optimization exemption, then starts reporting regardless of
  /// which of those were actually granted — none of them are required,
  /// only nice to have (see `device_location.dart`'s watchCurrentPosition).
  Future<void> allowBackgroundSharing() async {
    await ref.read(permissionServiceProvider).requestBackgroundSharing();
    // See _resolvePositionReporting's own comment — same guard, same reason.
    if (!ref.mounted) return;
    _showBackgroundSharingPrompt = false;
    _publish();
    _startReportingPosition();
  }

  /// The background-sharing explainer's Not now action: starts reporting
  /// straight away, the same foreground-only fallback a decline on any
  /// of those permissions would already leave a rider in.
  void skipBackgroundSharing() {
    _showBackgroundSharingPrompt = false;
    _publish();
    _startReportingPosition();
  }

  void _startReportingPosition() {
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    final positions = ref.read(positionRepositoryProvider);
    debugPrint('position stream started for ride ${_ride.id}, uid $uid');
    _positionReportSubscription = watchCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    ).listen(
      (position) {
        debugPrint(
          'reportPosition: ride ${_ride.id} uid $uid '
          '(${position.latitude}, ${position.longitude})',
        );
        // Other riders' markers already read straight from RTDB
        // (ridersForRideProvider), but this device's own camera-follow
        // target and the distances shown *to* other riders both key off
        // _selfLocation — without refreshing it here, both go stale
        // after the first fix (recenter() is otherwise the only thing
        // that ever touches it again).
        _selfLocation = LatLng(position.latitude, position.longitude);
        _hasResolvedSelfLocation = true;
        _checkReachedDestination();
        _publish();
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

  /// Arms the server-side isOnline cleanup for this device's own position
  /// entry, and re-arms it after every reconnect — an onDisconnect
  /// registration fires (and needs re-establishing) at most once per
  /// connection, not once per app session, so a brief network drop and
  /// reconnect without this would leave later disconnects unhandled.
  void _armDisconnectCleanup() {
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    final positions = ref.read(positionRepositoryProvider);
    _connectionSubscription = positions.watchConnected().listen((connected) {
      if (!connected) return;
      unawaited(
        positions
            .keepOnlineFlagInSyncOnDisconnect(rideId: _ride.id, uid: uid)
            .catchError((Object error, StackTrace stackTrace) {
              debugPrint(
                'keepOnlineFlagInSyncOnDisconnect failed for ride '
                '${_ride.id}: $error',
              );
            }),
      );
    });
  }

  Future<void> _checkInitialLocationAvailability() async {
    final available = await isLocationAvailable(
      permissionService: ref.read(permissionServiceProvider),
    );
    // See _resolvePositionReporting's own comment — same guard, same reason.
    if (!ref.mounted) return;
    _isLocationUnavailable = !available;
    _publish();
  }

  /// Opens the device's location settings — the rider-invisible banner's
  /// call to action. [watchLocationServicesEnabled] picks up the change
  /// live if they actually turn it on, no restart or manual re-check
  /// needed.
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Forces a fresh position report right away instead of waiting for the
  /// next natural [_startReportingPosition] stream tick — called when the
  /// app comes back to the foreground (see `HomeScreen`'s
  /// `didChangeAppLifecycleState`). Without this, a rider who's simply
  /// screen-locked or switched apps for a while reads as stale ("Last
  /// seen Xm ago") to the rest of the group the moment `staleRiderThreshold`
  /// elapses, even though they're still very much in the ride — the
  /// stream only reports again once the device actually moves ~10m
  /// (`_platformLocationSettings`'s distanceFilter), which doing nothing
  /// but sitting in the app doesn't trigger.
  ///
  /// No-op before reporting has actually started (e.g. the
  /// background-sharing prompt is still up) — nothing to refresh yet.
  Future<void> syncLocationNow() async {
    if (_positionReportSubscription == null) return;
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    final position = await acquireCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    );
    // See _resolvePositionReporting's own comment — same guard, same reason.
    if (!ref.mounted) return;
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _hasResolvedSelfLocation = true;
    _checkReachedDestination();
    _publish();
    final positions = ref.read(positionRepositoryProvider);
    unawaited(
      positions
          .reportPosition(
            rideId: _ride.id,
            uid: uid,
            lat: position.latitude,
            lng: position.longitude,
          )
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('syncLocationNow reportPosition failed for ${_ride.id}: $error');
          }),
    );
  }

  /// Flags [HomeUiState.showReachedDestinationPrompt] the first time this
  /// device's own live position lands within
  /// [reachedDestinationRadiusMeters] of the ride's destination.
  /// [_hasShownReachedPrompt] is sticky — once set, this never re-arms
  /// for the rest of the ride, even if the rider wanders back out of the
  /// radius and in again. Doesn't publish itself; every call site already
  /// calls [_publish] right after.
  void _checkReachedDestination() {
    if (_hasShownReachedPrompt) return;
    final destination = _ride.destination;
    if (destination == null) return;
    if (!isNearDestination(_selfLocation, destination)) return;
    _hasShownReachedPrompt = true;
    _showReachedDestinationPrompt = true;
  }

  /// Closes the reached-destination prompt without changing sharing — the
  /// dialog's "Keep sharing" choice. [stopSharingLocation] closes it too,
  /// for "Stop sharing"; either way [_hasShownReachedPrompt] staying true
  /// is what keeps the prompt from reappearing.
  void dismissReachedDestinationPrompt() {
    _showReachedDestinationPrompt = false;
    _publish();
  }

  /// Stops this device's own position reporting and marks it offline
  /// right away, rather than waiting for [staleRiderThreshold] to notice
  /// — the reached-destination prompt's "Stop sharing" choice. Unlike
  /// [endOrLeaveRide], this keeps the rider in the ride, still watching
  /// everyone else; [resumeSharingLocation] is the way back.
  void stopSharingLocation() {
    unawaited(_positionReportSubscription?.cancel());
    _positionReportSubscription = null;
    _isSharingPaused = true;
    _publish();
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    unawaited(
      ref
          .read(positionRepositoryProvider)
          .markOffline(rideId: _ride.id, uid: uid)
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('markOffline failed for ${_ride.id}: $error');
          }),
    );
  }

  /// Turns position reporting back on after [stopSharingLocation] — the
  /// paused-sharing banner's call to action.
  void resumeSharingLocation() {
    if (_positionReportSubscription != null) return;
    _isSharingPaused = false;
    _publish();
    _startReportingPosition();
  }

  /// Re-acquires the device's location, recenters on it, and marks the
  /// map as following the user again.
  Future<void> recenter() async {
    final position = await acquireCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    );
    // See _resolvePositionReporting's own comment — same guard, same reason.
    if (!ref.mounted) return;
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
  /// just removes them from it. Throws (letting the View show an error)
  /// only if that part fails — the actual leave/end already having
  /// succeeded is what matters to the caller, not whether the RTDB
  /// tidy-up below also happened to.
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
    // to always do it here regardless of which branch ran. Best-effort:
    // by the time this runs the backend has already flipped this
    // rider's RTDB presence to absent, so a failure here (this device
    // lost its connection right at the wrong moment, say) shouldn't
    // make an otherwise-successful leave/end look like it failed —
    // staleRiderThreshold already covers a position entry that's just
    // never updated again.
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid != null) {
      try {
        await ref
            .read(positionRepositoryProvider)
            .clearPosition(rideId: _ride.id, uid: uid);
      } catch (error) {
        debugPrint('clearPosition failed after leaving ${_ride.id}: $error');
      }
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

  /// Toggles the name label above a rider's marker — tapping the same
  /// uid again (or passing null) clears it. Driven by tapping a marker,
  /// a collapsed chip, or an expanded row, so map and sheet always agree
  /// on who's currently selected.
  void selectRider(String? uid) {
    _selectedRiderUid = _selectedRiderUid == uid ? null : uid;
    _publish();
  }

  /// Opens the Rider Info modal for [uid] — independent of
  /// [selectRider]/[_selectedRiderUid], so a sheet row's ⓘ doesn't also
  /// move the map's selection over to them.
  void showRiderInfo(String uid) {
    _infoRiderUid = uid;
    _publish();
  }

  void dismissRiderInfo() {
    _infoRiderUid = null;
    _publish();
  }

  /// Everything the Rider Info modal needs for [riderId], or null if
  /// that rider isn't in the currently-known list (e.g. they left while
  /// the modal was still open).
  ///
  /// Unlike the sheet row/map label's distances (straight-line, computed
  /// continuously as positions update), this uses the real Routes API
  /// for actual road distance — justified here specifically because it's
  /// only ever requested once, on an explicit tap, not on every position
  /// update the way a continuously-live figure would be.
  Future<RiderInfoDetails?> riderInfoFor(String riderId) async {
    Rider? rider;
    for (final candidate in _lastRiders) {
      if (candidate.riderId == riderId) {
        rider = candidate;
        break;
      }
    }
    if (rider == null) return null;

    final routes = ref.read(routesRepositoryProvider);
    final displayName = rider.isSelf ? 'You' : rider.displayName;

    String distanceFromSelfLabel;
    if (rider.isSelf) {
      distanceFromSelfLabel = 'This is you';
    } else {
      try {
        final selfToRider = await routes.computeRoute(
          origin: _selfLocation,
          destination: rider.location,
        );
        distanceFromSelfLabel =
            '${_formatDistance(selfToRider.distanceMeters.toDouble())} away from you';
      } catch (error) {
        // Never fatal to the rest of the modal — fall back to the same
        // straight-line math the sheet row already shows rather than an
        // empty field.
        debugPrint('computeRoute (self to rider) failed: $error');
        distanceFromSelfLabel =
            '${_formatDistance(_distanceFromSelf(rider))} away from you (approx.)';
      }
    }

    final destination = _ride.destination;
    String? distanceToDestinationLabel;
    String? relativeToSelfLabel;
    if (destination != null) {
      if (rider.isSelf) {
        // Reuses the route already computed once at ride start (_route)
        // instead of requesting your own distance to the destination
        // all over again — it's exactly the same figure. No
        // relativeToSelfLabel here: comparing yourself to yourself isn't
        // meaningful.
        final selfRoute = _route;
        if (selfRoute != null) {
          distanceToDestinationLabel =
              '${_formatDistance(selfRoute.distanceMeters.toDouble())} '
              'from destination';
        }
      } else {
        try {
          final riderToDestination = await routes.computeRoute(
            origin: rider.location,
            destination: LatLng(destination.lat, destination.lng),
          );
          distanceToDestinationLabel =
              '${_formatDistance(riderToDestination.distanceMeters.toDouble())} '
              'from destination';
          final selfToDestinationMeters = _route?.distanceMeters;
          if (selfToDestinationMeters != null) {
            relativeToSelfLabel = _formatRelativeToSelf(
              riderToDestination.distanceMeters.toDouble(),
              selfToDestinationMeters.toDouble(),
            );
          }
        } catch (error) {
          debugPrint('computeRoute (rider to destination) failed: $error');
        }
      }
    }

    return RiderInfoDetails(
      uid: rider.riderId,
      displayName: displayName,
      photoUrl: rider.photoUrl,
      isHost: rider.riderId == _ride.hostId,
      isOnline: rider.isOnline,
      lastUpdatedLabel: _formatLastUpdated(rider),
      distanceFromSelfLabel: distanceFromSelfLabel,
      distanceToDestinationLabel: distanceToDestinationLabel,
      relativeToSelfLabel: relativeToSelfLabel,
      canNavigate: !rider.isSelf,
      canRemove: _isHost && !rider.isSelf,
      isSelf: rider.isSelf,
      hasReachedDestination:
          destination != null && isNearDestination(rider.location, destination),
    );
  }

  /// Removes [riderId] from the ride — the backend re-checks that the
  /// caller is the host itself (see [RiderInfoDetails.canRemove], which
  /// only keeps the button from rendering for anyone else client-side).
  /// The rider's own device stops being able to report a position the
  /// moment this succeeds (database.rules.json), so there's nothing
  /// further to do here for that to take effect on everyone else's map.
  Future<void> removeRider(String riderId) async {
    await ref.read(rideRepositoryProvider).removeMember(_ride.id, riderId);
  }

  /// Opens the device's default maps app for turn-by-turn directions to
  /// [riderId]'s last known position — a straight hand-off to Apple/
  /// Google Maps, not our own in-app Routes API: that's metered per
  /// call, and paying for a full route for every rider someone might tap
  /// on isn't worth it when the OS-level maps app already does this for
  /// free.
  Future<void> openDirections(String riderId) async {
    final location = locationOf(riderId);
    if (location == null) return;
    final lat = location.latitude;
    final lng = location.longitude;
    final uri = Platform.isIOS
        ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng')
        : Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('openDirections failed for $riderId: $error');
    }
  }

  double _distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  /// E.g. "1.2 km ahead of you" — riderToDestination smaller than
  /// selfToDestination means that rider has less distance left to cover
  /// than you do, i.e. they're ahead, not that they're geographically in
  /// front of you.
  String _formatRelativeToSelf(
    double riderToDestination,
    double selfToDestination,
  ) {
    final diffKm = (selfToDestination - riderToDestination) / 1000;
    if (diffKm.abs() < 0.1) return 'About the same distance to go as you';
    final formatted = diffKm.abs().toStringAsFixed(1);
    return diffKm > 0 ? '$formatted km ahead of you' : '$formatted km behind you';
  }

  String _formatLastUpdated(Rider rider) {
    if (rider.isOnline) return 'Online';
    final age = DateTime.now().difference(rider.updatedAt);
    if (age.inMinutes < 1) return 'Last seen just now';
    if (age.inMinutes < 60) return 'Last seen ${age.inMinutes}m ago';
    return 'Last seen ${age.inHours}h ago';
  }

  Future<void> _resolveInitialLocation() async {
    final position = await acquireCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    );
    // See _resolvePositionReporting's own comment — same guard, same reason.
    if (!ref.mounted) return;
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _hasResolvedSelfLocation = true;
    _publish();
    unawaited(_computeRouteToDestinationIfNeeded());
  }

  /// Computes the route from this rider's starting point to the
  /// destination once, the first time both are known — not on every
  /// position update: the destination is a fixed meet-up pin, not
  /// turn-by-turn navigation, so continuously recomputing as the rider
  /// moves would just be a paid API call for a line that wouldn't
  /// visibly change much ride to ride.
  ///
  /// The origin is [PositionRepository.resolveStartLocation], not
  /// `_selfLocation` directly — `_selfLocation` is wherever this device
  /// is the instant this happens to run, which is only actually "the
  /// start" the very first time. Closing and reopening the app mid-ride
  /// re-runs this same method (a fresh `HomeViewModel`, so
  /// `_hasRequestedRoute` resets too), and without a persisted start it
  /// would silently redraw this route from wherever the rider is by the
  /// time they reopen the app instead of where they actually began.
  Future<void> _computeRouteToDestinationIfNeeded() async {
    if (_hasRequestedRoute) return;
    final destination = _ride.destination;
    if (destination == null) return;
    final uid = ref.read(firebaseAuthServiceProvider).currentUser?.uid;
    if (uid == null) return;
    _hasRequestedRoute = true;

    try {
      final startLocation = await ref
          .read(positionRepositoryProvider)
          .resolveStartLocation(
            rideId: _ride.id,
            uid: uid,
            lat: _selfLocation.latitude,
            lng: _selfLocation.longitude,
          );
      // See _resolvePositionReporting's own comment — same guard, same
      // reason: the await above is an async gap this provider could have
      // been disposed during.
      if (!ref.mounted) return;
      final route = await ref
          .read(routesRepositoryProvider)
          .computeRoute(
            origin: startLocation,
            destination: LatLng(destination.lat, destination.lng),
          );
      // Same reason again — a second, independent async gap.
      if (!ref.mounted) return;
      _route = route;
      _publish();
    } catch (error) {
      // Never fatal to the rest of the screen — the destination pin and
      // straight-line rider distances already work without this; a
      // rider just doesn't get a route line/ETA this session.
      debugPrint('computeRoute failed for ride ${_ride.id}: $error');
    }
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
      showBackgroundSharingPrompt: _showBackgroundSharingPrompt,
      showReachedDestinationPrompt: _showReachedDestinationPrompt,
      isSharingPaused: _isSharingPaused,
      routePolyline: _route?.points ?? const [],
      routeSummary: _route == null ? null : _formatRouteSummary(_route!),
      selectedRiderUid: _selectedRiderUid,
      infoRiderUid: _infoRiderUid,
    );
  }

  /// Distance only, not duration — computed once at the start of the ride
  /// (see _computeRouteToDestinationIfNeeded), so a duration would read
  /// as a live ETA it isn't. "from start" makes the distance's own
  /// staleness explicit too, rather than implying it tracks the rider's
  /// current position.
  String _formatRouteSummary(RouteInfo route) {
    final km = (route.distanceMeters / 1000).toStringAsFixed(1);
    return '$km km from start';
  }

  /// Self first, then everyone else nearest-first.
  List<Rider> _sortedByDistance(List<Rider> riders) {
    final others = riders.where((rider) => !rider.isSelf).toList()
      ..sort((a, b) => _distanceFromSelf(a).compareTo(_distanceFromSelf(b)));
    final self = riders.where((rider) => rider.isSelf);
    return [...self, ...others];
  }

  double _distanceFromSelf(Rider rider) =>
      _distanceBetween(_selfLocation, rider.location);

  RiderVm _toRiderVm(Rider rider) {
    final distanceLabel = rider.isSelf
        ? 'You'
        : (_hasResolvedSelfLocation
              ? _formatDistance(_distanceFromSelf(rider))
              : '—');
    final destination = _ride.destination;
    return RiderVm(
      uid: rider.riderId,
      displayName: rider.isSelf ? 'You' : rider.displayName,
      photoUrl: rider.photoUrl,
      distanceLabel: distanceLabel,
      isOnline: rider.isOnline,
      isSelf: rider.isSelf,
      isHost: rider.riderId == _ride.hostId,
      hasReachedDestination:
          destination != null && isNearDestination(rider.location, destination),
    );
  }

  String _formatDistance(double meters) =>
      '${(meters / 1000).toStringAsFixed(1)} km';
}
