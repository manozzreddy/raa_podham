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
            final lat = value['lat'] as num?;
            final lng = value['lng'] as num?;
            if (lat == null || lng == null) return null;
            // Absent for a position written before this field existed —
            // treat as "just now" rather than flagging an old entry stale
            // the instant this ships.
            final updatedAtMillis = value['updatedAt'] as int?;
            return RiderPosition(
              riderId: entry.key as String,
              location: LatLng(lat.toDouble(), lng.toDouble()),
              isOnline: value['isOnline'] as bool? ?? true,
              updatedAt: updatedAtMillis == null
                  ? DateTime.now()
                  : DateTime.fromMillisecondsSinceEpoch(updatedAtMillis),
            );
          })
          .whereType<RiderPosition>()
          .toList(growable: false);
    });
  }

  /// Writes this device's own live location — the RTDB rule for this path
  /// (`database.rules.json`) only lets `uid` write its own entry, so this
  /// can never be used to spoof another rider's position. `updatedAt` is
  /// how [Rider.merge] tells a genuinely live rider from a stale one
  /// nobody's marked offline yet.
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
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Arms a server-side cleanup for this device's own position entry,
  /// triggered the moment RTDB detects this connection is gone, whether
  /// from a crash, a force-quit, or just losing network, not only a
  /// graceful leave/end. Keeps the rider's last known spot on the map
  /// (rather than removing it outright) but flips `isOnline` false, the
  /// same flag the rider sheet's status dot already reads. Must be
  /// re-armed after every reconnect, since it fires at most once per
  /// connection — see [HomeViewModel] for how it re-registers itself
  /// after a reconnect via `watchConnected`.
  Future<void> keepOnlineFlagInSyncOnDisconnect({
    required String rideId,
    required String uid,
  }) {
    return _database
        .ref('rides/$rideId/positions/$uid')
        .onDisconnect()
        .update({'isOnline': false});
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

  /// True while this device has an active connection to the Realtime
  /// Database, RTDB's own reserved `.info/connected` path. An
  /// `onDisconnect` registration fires (and needs re-establishing) at
  /// most once per connection, not once per app session, so
  /// [HomeViewModel] re-arms [keepOnlineFlagInSyncOnDisconnect] every
  /// time this flips back to true rather than only once at startup.
  Stream<bool> watchConnected() {
    return _database.ref('.info/connected').onValue.map(
      (event) => event.snapshot.value as bool? ?? false,
    );
  }
}

@riverpod
PositionRepository positionRepository(Ref ref) => PositionRepository();
