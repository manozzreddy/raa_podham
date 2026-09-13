// Basic smoke test: the app root builds and routes to sign-in when
// signed out, without touching real Firebase or the network.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raa_podham/app.dart';
import 'package:raa_podham/services/firebase_auth_service.dart';
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

void main() {
  testWidgets('RaaPodhamApp routes signed-out users to sign-in', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthServiceProvider.overrideWithValue(_FakeFirebaseAuthService()),
        ],
        child: const RaaPodhamApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Raa Podham'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
