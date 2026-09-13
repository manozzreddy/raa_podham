// Unit tests for CreateRideViewModel — the simplified new-ride form
// state (name + a picked destination + submit), now that destination
// search itself lives in DestinationSearchViewModel instead.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
