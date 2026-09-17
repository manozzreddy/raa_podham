import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/permission_service.dart';
import '../data/device_location.dart';
import 'home_view_model.dart' show fallbackSelfLocation;

part 'no_active_ride_view_model.g.dart';

/// What the landing map needs when the signed-in user isn't currently in
/// a ride: just the device's own position, no riders/ride to render.
class NoActiveRideUiState {
  const NoActiveRideUiState({
    required this.selfLocation,
    required this.isFollowingUser,
  });

  final LatLng selfLocation;
  final bool isFollowingUser;
}

/// The landing screen's view model for when there's no active ride.
///
/// Mirrors [HomeViewModel]'s self-location/follow mechanics exactly (down
/// to sharing [acquireCurrentPosition]) but with no ride to merge them
/// with — kept as its own small notifier rather than a degenerate case of
/// [HomeViewModel], since that one is keyed on a [Ride] it wouldn't have
/// yet.
@riverpod
class NoActiveRideViewModel extends _$NoActiveRideViewModel {
  bool _hasStartedLocationResolution = false;
  LatLng _selfLocation = fallbackSelfLocation;
  bool _isFollowingUser = true;

  @override
  Future<NoActiveRideUiState> build() async {
    if (!_hasStartedLocationResolution) {
      _hasStartedLocationResolution = true;
      unawaited(_resolveInitialLocation());
    }
    return _currentState();
  }

  /// Re-acquires the device's location, recenters on it, and marks the
  /// map as following the user again.
  Future<void> recenter() async {
    final position = await acquireCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    );
    // The user could navigate away (e.g. into a ride) while the await
    // above is pending, disposing this auto-dispose provider — touching
    // `ref`/`state` after that throws UnmountedRefException.
    if (!ref.mounted) return;
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

  Future<void> _resolveInitialLocation() async {
    final position = await acquireCurrentPosition(
      permissionService: ref.read(permissionServiceProvider),
    );
    // See recenter's own comment — same guard, same reason.
    if (!ref.mounted) return;
    if (position == null) return;
    _selfLocation = LatLng(position.latitude, position.longitude);
    _publish();
  }

  void _publish() => state = AsyncData(_currentState());

  NoActiveRideUiState _currentState() {
    return NoActiveRideUiState(
      selfLocation: _selfLocation,
      isFollowingUser: _isFollowingUser,
    );
  }
}
