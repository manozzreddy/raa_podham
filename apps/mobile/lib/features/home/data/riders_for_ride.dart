import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

import '../../../services/providers.dart';
import '../models/rider.dart';
import '../models/rider_position.dart';
import '../models/rider_profile.dart';
import 'membership_repository.dart';
import 'position_repository.dart';

part 'riders_for_ride.g.dart';

/// The ride's riders, ready to render: [PositionRepository]'s live
/// locations merged with [MembershipRepository]'s profiles.
@riverpod
Stream<List<Rider>> ridersForRide(Ref ref, String rideId) {
  final positions = ref.watch(positionRepositoryProvider).watchPositions(rideId);
  final profiles = ref.watch(membershipRepositoryProvider).watchMembers(rideId);
  final currentUserId = ref.watch(firebaseAuthServiceProvider).currentUser?.uid;

  return Rx.combineLatest2<List<RiderPosition>, List<RiderProfile>, List<Rider>>(
    positions,
    profiles,
    (positions, profiles) {
      final profileById = {for (final profile in profiles) profile.riderId: profile};
      return positions
          .map(
            (position) => Rider.merge(
              position: position,
              profile: profileById[position.riderId],
              currentUserId: currentUserId,
            ),
          )
          .toList(growable: false);
    },
  );
}
