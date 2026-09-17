// Widget test for CreateRideScreen's Create button enabled state.
//
// The destination field is a tap-to-navigate control (it pushes
// DestinationSearchScreen, which needs a real GoRouter this test
// deliberately doesn't set up) — so a destination is selected here by
// calling the ViewModel directly via the widget tree's own
// ProviderContainer, the same end state a real selection would produce.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raa_podham/features/rides/view/create_ride_screen.dart';
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
  testWidgets(
    'Create button stays disabled until both a name and a destination are set',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthServiceProvider.overrideWithValue(
              _FakeFirebaseAuthService(),
            ),
          ],
          child: const MaterialApp(home: CreateRideScreen()),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton createButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create ride'),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CreateRideScreen)),
      );

      expect(createButton().onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Ride name'),
        'Sunday Sunrise Ride',
      );
      await tester.pump();
      expect(
        createButton().onPressed,
        isNull,
        reason: 'still no destination selected',
      );

      container
          .read(createRideViewModelProvider(null).notifier)
          .selectDestination(_destination);
      await tester.pump();
      expect(createButton().onPressed, isNotNull);
    },
  );
}
