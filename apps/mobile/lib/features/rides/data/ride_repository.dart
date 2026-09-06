import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/api_client.dart';
import '../../../services/providers.dart';
import '../models/ride.dart';

part 'ride_repository.g.dart';

/// Talks to the Cloud Run backend's ride endpoints — the only class that
/// should import [ApiClient] for ride-related calls.
class RideRepository {
  RideRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Ride> createRide({required String name}) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/rides', data: {'name': name});
    return Ride.fromJson(response.data!);
  }

  Future<Ride> joinRide(String inviteCode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/rides/join',
      data: {'inviteCode': inviteCode},
    );
    return Ride.fromJson(response.data!);
  }

  Future<void> leaveRide(String rideId) => _apiClient.post<void>('/rides/$rideId/leave');

  Future<void> endRide(String rideId) => _apiClient.post<void>('/rides/$rideId/end');

  Future<List<Ride>> myRides() async {
    final response = await _apiClient.get<List<dynamic>>('/rides/mine');
    final rides = response.data ?? const [];
    return rides.map((json) => Ride.fromJson(json as Map<String, dynamic>)).toList(growable: false);
  }
}

@riverpod
RideRepository rideRepository(Ref ref) => RideRepository(ref.watch(apiClientProvider));
