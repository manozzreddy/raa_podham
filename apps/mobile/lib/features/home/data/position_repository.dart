import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/rider_position.dart';

part 'position_repository.g.dart';

/// Wraps the Realtime Database ride-positions node — the only class that
/// should import `package:firebase_database`.
class PositionRepository {
  PositionRepository([FirebaseDatabase? database]) : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  Stream<List<RiderPosition>> watchPositions(String rideId) {
    return _database.ref('rides/$rideId/positions').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return const <RiderPosition>[];

      return raw.entries.map((entry) {
        final value = Map<Object?, Object?>.from(entry.value as Map);
        return RiderPosition(
          riderId: entry.key as String,
          location: LatLng(
            (value['lat'] as num).toDouble(),
            (value['lng'] as num).toDouble(),
          ),
          isOnline: value['isOnline'] as bool? ?? true,
        );
      }).toList(growable: false);
    });
  }
}

@riverpod
PositionRepository positionRepository(Ref ref) => PositionRepository();
