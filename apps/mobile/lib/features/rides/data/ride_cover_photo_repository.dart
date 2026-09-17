import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/firebase_auth_service.dart';
import '../../../services/providers.dart';

part 'ride_cover_photo_repository.g.dart';

/// Uploads a ride's cover photo to Firebase Storage — the only class that
/// should import `firebase_storage`, matching how `RideRepository` is the
/// only one importing `dio`.
///
/// Uploaded to a path scoped by the uploading user's own uid
/// (`rideCoverPhotos/{uid}/...`), not the ride's — a ride's ID is only
/// generated server-side once it's created, so there's nothing to scope
/// the path to yet at the point [CreateRideScreen] lets someone pick a
/// photo. See `storage.rules` for the matching security rule.
class RideCoverPhotoRepository {
  RideCoverPhotoRepository(this._storage, this._auth);

  final FirebaseStorage _storage;
  final FirebaseAuthService _auth;

  /// Uploads [file] and returns its public download URL, ready to pass
  /// straight into `RideRepository.createRide`'s `coverPhotoUrl`.
  Future<String> uploadCoverPhoto(File file) async {
    // Read fresh rather than captured at construction time: this
    // provider is `keepAlive`, so a cached uid would go stale across a
    // sign-out/sign-in as a different user in the same app session.
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('uploadCoverPhoto requires a signed-in user');
    }
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref('rideCoverPhotos/$uid/$fileName');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Deletes a previously uploaded cover photo — the "remove photo" action
  /// on the create-ride form, and best-effort only: a failure here (the
  /// user already navigated away, a network blip) just leaves an orphaned
  /// file rather than blocking anything.
  Future<void> deleteCoverPhoto(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }
}

@Riverpod(keepAlive: true)
RideCoverPhotoRepository rideCoverPhotoRepository(Ref ref) {
  return RideCoverPhotoRepository(
    FirebaseStorage.instance,
    ref.watch(firebaseAuthServiceProvider),
  );
}
