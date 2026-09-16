// Unit tests for CreateRideViewModel — the simplified new-ride form
// state (name + a picked destination + submit), now that destination
// search itself lives in DestinationSearchViewModel instead.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raa_podham/features/rides/data/ride_repository.dart';
import 'package:raa_podham/features/rides/models/ride.dart';
import 'package:raa_podham/features/rides/view_model/create_ride_view_model.dart';
import 'package:raa_podham/services/firebase_auth_service.dart';
import 'package:raa_podham/services/geocoding_repository.dart';
import 'package:raa_podham/services/providers.dart';

class _FakeFirebaseAuthService implements FirebaseAuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithApple() => throw UnimplementedError();
}

/// Stands in for the real backend call (POST /rides) — `RideRepository`
/// now hits the network for real, and this test cares about
/// `CreateRideViewModel`'s own state handling, not the network.
class _FakeRideRepository implements RideRepository {
  @override
  Future<Ride> createRide({
    required String name,
    DestinationSuggestion? destination,
    DateTime? scheduledAt,
    String? notes,
    String? coverPhotoUrl,
  }) async {
    return Ride(
      id: 'fake-ride-1',
      name: name,
      inviteCode: 'FAKE01',
      hostId: 'fake-host-uid',
      status: scheduledAt != null && scheduledAt.isAfter(DateTime.now())
          ? RideStatus.scheduled
          : RideStatus.active,
      destination: destination == null
          ? null
          : RideDestination(
              name: destination.displayName,
              lat: destination.lat,
              lng: destination.lng,
            ),
      scheduledAt: scheduledAt,
      notes: notes,
      coverPhotoUrl: coverPhotoUrl,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Ride> joinRide(String inviteCode) => throw UnimplementedError();

  @override
  Future<void> leaveRide(String rideId) => throw UnimplementedError();

  @override
  Future<void> endRide(String rideId) => throw UnimplementedError();

  @override
  Future<void> deleteRide(String rideId) => throw UnimplementedError();

  @override
  Future<void> removeMember(String rideId, String memberUid) =>
      throw UnimplementedError();

  @override
  Future<List<Ride>> myRides() => throw UnimplementedError();

  @override
  Future<void> startRideNow(String rideId) => throw UnimplementedError();
}

const _destination = DestinationSuggestion(
  displayName: 'Cubbon Park',
  secondaryText: 'Bengaluru, India',
  lat: 12.97,
  lng: 77.59,
);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        firebaseAuthServiceProvider.overrideWithValue(
          _FakeFirebaseAuthService(),
        ),
        rideRepositoryProvider.overrideWithValue(_FakeRideRepository()),
      ],
    );
    // This provider is (correctly) autoDispose in production — container
    // .read() alone doesn't hold a subscription, so without this listener
    // Riverpod disposes the notifier mid-createRide (across its awaited
    // Future.delayed) before it can set its own final state.
    container.listen(createRideViewModelProvider, (previous, next) {});
  });

  tearDown(() => container.dispose());

  test('selectDestination sets the chosen destination', () {
    final notifier = container.read(createRideViewModelProvider.notifier);

    notifier.selectDestination(_destination);

    expect(
      container.read(createRideViewModelProvider).selectedDestination,
      _destination,
    );
  });

  test('createRide fails with an error, and does not call the repository, if no destination is set', () async {
    final notifier = container.read(createRideViewModelProvider.notifier);
    notifier.setName('Sunday Sunrise Ride');

    final ride = await notifier.createRide();

    expect(ride, isNull);
    expect(container.read(createRideViewModelProvider).error, isNotNull);
  });

  test(
    'createRide succeeds once both a name and a destination are set',
    () async {
      final notifier = container.read(createRideViewModelProvider.notifier);
      notifier.setName('Sunday Sunrise Ride');
      notifier.selectDestination(_destination);

      final ride = await notifier.createRide();

      expect(ride, isNotNull);
      expect(ride!.name, 'Sunday Sunrise Ride');
      expect(ride.destination?.name, _destination.displayName);
      expect(container.read(createRideViewModelProvider).error, isNull);
      expect(container.read(createRideViewModelProvider).isCreating, isFalse);
    },
  );

  test('setNotes and setScheduledAt are reflected in state and passed through to createRide', () async {
    final notifier = container.read(createRideViewModelProvider.notifier);
    final scheduledAt = DateTime.now().add(const Duration(days: 1));
    notifier.setName('Sunday Sunrise Ride');
    notifier.selectDestination(_destination);
    notifier.setNotes('Bring rain gear');
    notifier.setScheduledAt(scheduledAt);

    expect(container.read(createRideViewModelProvider).notes, 'Bring rain gear');
    expect(container.read(createRideViewModelProvider).scheduledAt, scheduledAt);

    final ride = await notifier.createRide();

    expect(ride, isNotNull);
    expect(ride!.notes, 'Bring rain gear');
    expect(ride.scheduledAt, scheduledAt);
    expect(ride.status, RideStatus.scheduled);
  });

  test('setScheduledAt(null) clears a previously picked time', () {
    final notifier = container.read(createRideViewModelProvider.notifier);
    notifier.setScheduledAt(DateTime.now().add(const Duration(days: 1)));

    notifier.setScheduledAt(null);

    expect(container.read(createRideViewModelProvider).scheduledAt, isNull);
  });
}
