import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/rider_position.dart';

part 'position_repository.g.dart';

/// Wraps the Realtime Database ride-positions node — the only class that
/// should import `package:firebase_database`.
class PositionRepository {
  PositionRepository([FirebaseDatabase? database])
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  Stream<List<RiderPosition>> watchPositions(String rideId) {
    return _database.ref('rides/$rideId/positions').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return const <RiderPosition>[];

      return raw.entries
          .map((entry) {
            final value = Map<Object?, Object?>.from(entry.value as Map);
            return RiderPosition(
              riderId: entry.key as String,
              location: LatLng(
                (value['lat'] as num).toDouble(),
                (value['lng'] as num).toDouble(),
              ),
              isOnline: value['isOnline'] as bool? ?? true,
            );
          })
          .toList(growable: false);
    });
  }

  /// Writes this device's own live location — the RTDB rule for this path
  /// (`database.rules.json`) only lets `uid` write its own entry, so this
  /// can never be used to spoof another rider's position.
  Future<void> reportPosition({
    required String rideId,
    required String uid,
    required double lat,
    required double lng,
  }) {
    return _database.ref('rides/$rideId/positions/$uid').set({
      'lat': lat,
      'lng': lng,
      'isOnline': true,
    });
  }

  /// Removes this device's own position entry — called when the rider
  /// actually leaves/ends the ride (not just navigates away from the
  /// screen), so they don't linger as a stale marker for everyone who
  /// stayed. `RTDBPresenceRepository.ClearRide` on the backend already
  /// wipes this whole subtree when the host ends the ride; this is for
  /// the "a regular member leaves" case, which only removes that one
  /// member's own entries.
  Future<void> clearPosition({required String rideId, required String uid}) {
    return _database.ref('rides/$rideId/positions/$uid').remove();
  }
}

@riverpod
PositionRepository positionRepository(Ref ref) => PositionRepository();
