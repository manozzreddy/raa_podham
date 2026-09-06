import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'rider_position.dart';
import 'rider_profile.dart';

/// A group member ready to render: [RiderPosition] (Realtime Database)
/// merged with [RiderProfile] (Firestore membership), plus whether this
/// rider is the signed-in user.
class Rider {
  const Rider({
    required this.riderId,
    required this.displayName,
    required this.location,
    required this.isOnline,
    required this.isSelf,
  });

  factory Rider.merge({
    required RiderPosition position,
    required RiderProfile? profile,
    required String? currentUserId,
  }) {
    return Rider(
      riderId: position.riderId,
      displayName: profile?.displayName ?? 'Rider',
      location: position.location,
      isOnline: position.isOnline,
      isSelf: position.riderId == currentUserId,
    );
  }

  final String riderId;
  final String displayName;
  final LatLng location;
  final bool isOnline;
  final bool isSelf;
}

/// "You" for the current rider, otherwise the distance from
/// [selfLocation] to [rider], formatted like "2.3 km".
String formatRiderDistance(Rider rider, LatLng selfLocation) {
  if (rider.isSelf) return 'You';
  final meters = Geolocator.distanceBetween(
    selfLocation.latitude,
    selfLocation.longitude,
    rider.location.latitude,
    rider.location.longitude,
  );
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
