import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_repository.g.dart';

/// Wraps the users/{uid} Firestore document — the signed-in user's own
/// profile, written right after sign-in so the backend can populate a
/// ride member's displayName/photoUrl from it (RideService.applyProfile
/// on the Go side). The only class that should import
/// `package:cloud_firestore` for this collection.
class UserProfileRepository {
  UserProfileRepository([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> upsertCurrentUserProfile({
    required String uid,
    required String? displayName,
    required String? photoUrl,
    required String? email,
  }) {
    final data = <String, Object?>{
      'displayName': displayName ?? 'Rider',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (email != null) data['email'] = email;

    return _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}

@riverpod
UserProfileRepository userProfileRepository(Ref ref) => UserProfileRepository();
