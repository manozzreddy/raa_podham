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
    DateTime? scheduledAt,
    String? notes,
    String? coverPhotoUrl,
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
        if (scheduledAt != null)
          'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (coverPhotoUrl != null) 'coverPhotoUrl': coverPhotoUrl,
      },
    );
    return Ride.fromJson(response.data!);
  }

  /// The host's way of skipping the wait on a scheduled ride — the
  /// backend rejects this for anyone else, or for a ride that's already
  /// active or has ended.
  Future<void> startRideNow(String rideId) async {
    await _apiClient.post<void>('/rides/$rideId/start');
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

  /// Host-only, and only once the ride has actually ended — permanently
  /// removes it and everything tied to it (Firestore doc, members
  /// subcollection, invite code, and its now-already-cleared Realtime
  /// Database subtree). The backend rejects this for anyone else, or for
  /// a ride still scheduled or active.
  Future<void> deleteRide(String rideId) async {
    await _apiClient.delete<void>('/rides/$rideId');
  }

  /// Host-only — the backend rejects this for anyone else. Also flips
  /// that rider's RTDB presence to absent, which `database.rules.json`'s
  /// positions write rule now checks, so their device can't keep
  /// reporting a position after this succeeds.
  Future<void> removeMember(String rideId, String memberUid) async {
    await _apiClient.post<void>('/rides/$rideId/members/$memberUid/remove');
  }

  Future<List<Ride>> myRides() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/rides',
    );
    final data = response.data!;
    final active = (data['active'] as List<dynamic>? ?? []).cast<
      Map<String, dynamic>
    >();
    final upcoming = (data['upcoming'] as List<dynamic>? ?? []).cast<
      Map<String, dynamic>
    >();
    final past = (data['past'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return [
      ...active,
      ...upcoming,
      ...past,
    ].map(Ride.fromJson).toList(growable: false);
  }
}

@Riverpod(keepAlive: true)
RideRepository rideRepository(Ref ref) =>
    RideRepository(ref.watch(apiClientProvider));
