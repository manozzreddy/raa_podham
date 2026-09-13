import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/api_client.dart';
import '../../../services/geocoding_repository.dart';
import '../../../services/providers.dart';
import '../models/ride.dart';

part 'ride_repository.g.dart';

/// Talks to the Cloud Run backend's ride endpoints — the only class that
/// should import `ApiClient` for ride-related calls.
class RideRepository {
  RideRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Ride> createRide({
    required String name,
    DestinationSuggestion? destination,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/rides',
      data: {
        'name': name,
        if (destination != null)
          'destination': {
            'name': destination.displayName,
            'lat': destination.lat,
            'lng': destination.lng,
          },
      },
    );
    return Ride.fromJson(response.data!);
  }

  Future<Ride> joinRide(String inviteCode) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/rides/join',
      data: {'inviteCode': inviteCode},
    );
    return Ride.fromJson(response.data!);
  }

  Future<void> leaveRide(String rideId) async {
    await _apiClient.post<void>('/rides/$rideId/leave');
  }

  Future<void> endRide(String rideId) async {
    await _apiClient.post<void>('/rides/$rideId/end');
  }

  Future<List<Ride>> myRides() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/rides',
    );
    final data = response.data!;
    final active = (data['active'] as List<dynamic>? ?? []).cast<
      Map<String, dynamic>
    >();
    final past = (data['past'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return [...active, ...past].map(Ride.fromJson).toList(growable: false);
  }
}

@Riverpod(keepAlive: true)
RideRepository rideRepository(Ref ref) =>
    RideRepository(ref.watch(apiClientProvider));
