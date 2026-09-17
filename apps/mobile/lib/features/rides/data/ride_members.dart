import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/membership_repository.dart';
import '../../home/models/rider_profile.dart';

part 'ride_members.g.dart';

/// A ride's member list — just the static profile info ([RiderProfile]),
/// no live position tracking combined in the way `ridersForRideProvider`
/// does for an active ride. Used by `RideDetailScreen`, where there's
/// nothing live left to show once a ride has ended (and, for an upcoming
/// one, nothing live to show yet).
@riverpod
Stream<List<RiderProfile>> rideMembers(Ref ref, String rideId) {
  return ref.watch(membershipRepositoryProvider).watchMembers(rideId);
}
