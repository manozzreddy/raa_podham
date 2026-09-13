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
    this.photoUrl,
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
      photoUrl: profile?.photoUrl,
      location: position.location,
      isOnline: position.isOnline,
      isSelf: position.riderId == currentUserId,
    );
  }

  final String riderId;
  final String displayName;
  final String? photoUrl;
  final LatLng location;
  final bool isOnline;
  final bool isSelf;
}
