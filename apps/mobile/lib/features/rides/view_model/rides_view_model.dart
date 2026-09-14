import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/ride_repository.dart';
import '../models/ride.dart';

part 'rides_view_model.g.dart';

/// The signed-in user's rides.
@riverpod
class RidesViewModel extends _$RidesViewModel {
  @override
  Future<List<Ride>> build() {
    return ref.watch(rideRepositoryProvider).myRides();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rideRepositoryProvider).myRides(),
    );
  }
}

/// The join-ride form's submit action. Its own [AsyncValue], separate
/// from [RidesViewModel]'s list — [CreateRideViewModel] (its own file,
/// `create_ride_view_model.dart`) is the create-ride equivalent, though
/// shaped differently since that form has more going on (destination
/// search) than a single submit action.
@riverpod
class JoinRideViewModel extends _$JoinRideViewModel {
  @override
  Future<Ride?> build() async => null;

  Future<void> submit({required String inviteCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rideRepositoryProvider).joinRide(inviteCode),
    );
  }
}
