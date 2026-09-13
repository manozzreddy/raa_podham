import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase_auth_service.dart';
import '../../../services/geocoding_repository.dart';
import '../../../services/providers.dart';
import '../models/ride.dart';

part 'ride_repository.g.dart';

/// Talks to the Cloud Run backend's ride endpoints — the only class that
/// should import `ApiClient` for ride-related calls, once it does again.
///
/// Every method is mocked for now, per product direction, against
/// [_mockRides] — an in-memory stand-in for the backend, kept alive via
/// the `keepAlive` provider below so it survives navigating between
/// screens. Each method's doc comment notes the real call it stands in
/// for.
class RideRepository {
  RideRepository(this._authService);

  final FirebaseAuthService _authService;

  /// Seeded with one past ride so the no-ride sheet's rides list has
  /// something to render immediately.
  final List<Ride> _mockRides = [
    const Ride(
      id: 'mock-ride-seed-1',
      name: 'Sunday Morning Ride',
      inviteCode: 'X7K2QM',
      hostId: 'mock-host-uid',
      status: RideStatus.ended,
    ),
  ];

  /// Mocked. Real call: `POST /rides` with
  /// `{name, destination: destination == null ? null : {name, lat, lng}}`,
  /// returning a [Ride] (`internal/dto/ride_dto.go`'s `RideResponse`,
  /// extended with that same optional `destination` shape).
  Future<Ride> createRide({
    required String name,
    DestinationSuggestion? destination,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final ride = Ride(
      id: 'mock-ride-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      inviteCode: _mockInviteCode(),
      hostId: _authService.currentUser?.uid ?? 'mock-host-uid',
      status: RideStatus.active,
      destination: destination == null
          ? null
          : RideDestination(
              name: destination.displayName,
              lat: destination.lat,
              lng: destination.lng,
            ),
    );
    _mockRides.add(ride);
    return ride;
  }

  /// Mocked. Real call: `POST /rides/join` with `{inviteCode}`, returning
  /// a [Ride] hosted by whoever owns that code.
  Future<Ride> joinRide(String inviteCode) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final ride = Ride(
      id: 'mock-ride-$inviteCode',
      name: 'Mock Group Ride',
      inviteCode: inviteCode,
      hostId: 'mock-host-uid',
      status: RideStatus.active,
    );
    _mockRides.add(ride);
    return ride;
  }

  /// Mocked. Real call: `POST /rides/{id}/leave`. Removes the ride from
  /// this user's own list, same as the real endpoint dropping their
  /// membership would.
  Future<void> leaveRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockRides.removeWhere((ride) => ride.id == rideId);
  }

  /// Mocked. Real call: `POST /rides/{id}/end`. Marks the ride ended
  /// rather than removing it, so it shows up as a past ride afterwards.
  Future<void> endRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockRides.indexWhere((ride) => ride.id == rideId);
    if (index == -1) return;
    final ride = _mockRides[index];
    _mockRides[index] = Ride(
      id: ride.id,
      name: ride.name,
      inviteCode: ride.inviteCode,
      hostId: ride.hostId,
      status: RideStatus.ended,
    );
  }

  /// Mocked. Real call: `GET /users/me/rides`, returning
  /// `{active: [...], past: [...]}` (`MyRidesResponse`) — flattened here
  /// since every caller just wants the combined list.
  Future<List<Ride>> myRides() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_mockRides);
  }

  String _mockInviteCode() {
    // Same alphabet/length as the backend (internal/model/ride.go) so a
    // mocked code still looks like the real thing.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}

@Riverpod(keepAlive: true)
RideRepository rideRepository(Ref ref) =>
    RideRepository(ref.watch(firebaseAuthServiceProvider));
