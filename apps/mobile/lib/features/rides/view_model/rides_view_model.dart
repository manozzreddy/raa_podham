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

  /// The host's "start now" action on an upcoming ride's card — refreshes
  /// the list on success so [HomeScreen]'s own `_findActiveRide` picks up
  /// the now-active ride and switches to the map on its own, the same way
  /// ending/leaving a ride already does; no explicit navigation needed.
  /// Returns false (with the list left as is) if the backend rejects it —
  /// e.g. someone else beat the host to it, or the ride already ended.
  Future<bool> startRideNow(String rideId) async {
    try {
      await ref.read(rideRepositoryProvider).startRideNow(rideId);
    } catch (_) {
      return false;
    }
    await refresh();
    return true;
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
