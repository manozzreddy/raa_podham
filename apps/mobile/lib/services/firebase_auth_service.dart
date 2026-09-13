import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thin wrapper around [FirebaseAuth.instance] plus the Google and Apple
/// sign-in SDKs — the only file that should import `package:firebase_auth`,
/// `package:google_sign_in`, or `package:sign_in_with_apple`.
class FirebaseAuthService {
  FirebaseAuthService([FirebaseAuth? auth, GoogleSignIn? googleSignIn])
    : _authOverride = auth,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _authOverride;
  final GoogleSignIn _googleSignIn;

  // Deliberately lazy: touching FirebaseAuth.instance before Firebase.
  // initializeApp() has run throws, and a fake subclass used in tests
  // (which overrides every method below) should never trigger it.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<String?> getIdToken() =>
      _auth.currentUser?.getIdToken() ?? Future.value(null);

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-canceled',
        message: 'Google sign-in was canceled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com')
        .credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only ever sends the user's name on this very first
    // authorization — unlike Google, Firebase's own user record has no
    // name (or photo) from Apple at all otherwise, so this is the only
    // chance to persist it.
    final appleName =
        '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
            .trim();
    final currentName = userCredential.user?.displayName;
    if (appleName.isNotEmpty && (currentName == null || currentName.isEmpty)) {
      await userCredential.user?.updateDisplayName(appleName);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String _sha256ofString(String input) =>
    sha256.convert(utf8.encode(input)).toString();
