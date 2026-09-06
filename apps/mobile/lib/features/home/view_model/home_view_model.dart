import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../rides/data/ride_repository.dart';
import '../data/riders_for_ride.dart';
import '../models/rider.dart';

part 'home_view_model.g.dart';

/// Fallback map center, used until the device's own location resolves (or
/// if location permission/services aren't available): central Hyderabad.
const LatLng fallbackSelfLocation = LatLng(17.3850, 78.4867);

/// Sheet fractional extent past which the rider sheet counts as expanded.
const double sheetExpandedThreshold = 0.5;

/// Everything the home screen needs to render for one ride.
class HomeState {
  const HomeState({
    required this.selfLocation,
    required this.riders,
    required this.isFollowingUser,
    required this.isSheetExpanded,
  });

  final LatLng selfLocation;
  final List<Rider> riders;
  final bool isFollowingUser;
  final bool isSheetExpanded;

  /// Self first, then everyone else nearest-first — for the rider sheet.
  List<Rider> get sortedByDistance {
    final others = riders.where((rider) => !rider.isSelf).toList()
      ..sort((a, b) => _distanceFromSelf(a).compareTo(_distanceFromSelf(b)));
    final self = riders.where((rider) => rider.isSelf);
    return [...self, ...others];
  }

  double _distanceFromSelf(Rider rider) {
    return Geolocator.distanceBetween(
      selfLocation.latitude,
      selfLocation.longitude,
      rider.location.latitude,
      rider.location.longitude,
    );
  }
}

/// The home screen's view model, scoped to one ride.
///
/// Resolves the device's own location, merges it with
/// [ridersForRideProvider]'s live riders, and holds the screen's
/// interaction state (following/sheet-expanded). Widget-level concerns —
/// the `MapController`, the sheet's drag mechanics — stay in the View
/// (`HomeScreen`) and react to this state rather than living here.
@riverpod
class HomeViewModel extends _$HomeViewModel {
  bool _hasStartedLocationResolution = false;
  LatLng _selfLocation = fallbackSelfLocation;
  bool _isFollowingUser = true;
  bool _isSheetExpanded = false;
  late String _rideId;

  @override
  Future<HomeState> build(String rideId) async {
    _rideId = rideId;

    if (!_hasStartedLocationResolution) {
      _hasStartedLocationResolution = true;
      unawaited(_resolveInitialLocation());
    }

    final riders = await ref.watch(ridersForRideProvider(rideId).future);
    return _currentState(riders);
  }

  /// Re-acquires the device's location, recenters on it, and marks the
  /// map as following the user again.
  Future<void> recenter() async {
    final position = await _acquireCurrentPosition();
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
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

  /// The rider sheet's current fractional extent, reported on every drag
  /// tick; only flips [HomeState.isSheetExpanded] when it crosses
  /// [sheetExpandedThreshold].
  void onSheetExtentChanged(double extent) {
    final expanded = extent > sheetExpandedThreshold;
    if (expanded == _isSheetExpanded) return;
    _isSheetExpanded = expanded;
    _publish();
  }

  /// Placeholder until additional map tile styles are wired up.
  void toggleMapStyle() => HapticFeedback.selectionClick();

  Future<void> endRide() async {
    try {
      await ref.read(rideRepositoryProvider).endRide(_rideId);
    } catch (_) {
      // Best-effort: the screen is about to navigate away regardless.
    }
  }

  Future<void> _resolveInitialLocation() async {
    final position = await _acquireCurrentPosition();
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _publish();
  }

  Future<Position?> _acquireCurrentPosition() async {
    try {
      final permission = await Permission.locationWhenInUse.request();
      if (!permission.isGranted) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      // Permission plugins/location services can fail in ways specific to
      // the device (or be entirely unavailable, as in widget tests); fall
      // back to fallbackSelfLocation rather than taking the screen down.
      return null;
    }
  }

  /// Re-publishes [state] using the riders from the last successful
  /// [build], since a plain state-mutation method (unlike [build]) has no
  /// fresh value from [ridersForRideProvider] to work with.
  void _publish() {
    final riders = state.value?.riders ?? const [];
    state = AsyncData(_currentState(riders));
  }

  HomeState _currentState(List<Rider> riders) {
    return HomeState(
      selfLocation: _selfLocation,
      riders: riders,
      isFollowingUser: _isFollowingUser,
      isSheetExpanded: _isSheetExpanded,
    );
  }
}
