import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/models/rider_profile.dart';

part 'membership_repository.g.dart';

/// Wraps a ride's Firestore membership subcollection — the only class
/// that should import `package:cloud_firestore`. Cross-feature: read by
/// `home` (live rider tracking, via `riders_for_ride.dart`) and `rides`
/// (a past ride's member list, in `PastRideDetailScreen`) alike, which is
/// what moved it here from `features/home/data/` in the first place.
class MembershipRepository {
  MembershipRepository([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RiderProfile>> watchMembers(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('members')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RiderProfile(
                  riderId: doc.id,
                  displayName:
                      (doc.data()['displayName'] as String?) ?? 'Rider',
                  photoUrl: doc.data()['photoUrl'] as String?,
                ),
              )
              .toList(growable: false),
        );
  }
}

@riverpod
MembershipRepository membershipRepository(Ref ref) => MembershipRepository();
