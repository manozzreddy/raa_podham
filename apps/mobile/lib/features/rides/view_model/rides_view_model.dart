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
    state = await AsyncValue.guard(() => ref.read(rideRepositoryProvider).myRides());
  }
}

/// The create-ride form's submit action.
///
/// Kept separate from [RidesViewModel] so the list's loading/error state
/// and the form's submit loading/error state don't share one [AsyncValue].
@riverpod
class CreateRideViewModel extends _$CreateRideViewModel {
  @override
  Future<Ride?> build() async => null;

  Future<void> submit({required String name}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(rideRepositoryProvider).createRide(name: name));
  }
}

/// The join-ride form's submit action. Same reasoning as
/// [CreateRideViewModel] — its own [AsyncValue], separate from the list.
@riverpod
class JoinRideViewModel extends _$JoinRideViewModel {
  @override
  Future<Ride?> build() async => null;

  Future<void> submit({required String inviteCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(rideRepositoryProvider).joinRide(inviteCode));
  }
}
