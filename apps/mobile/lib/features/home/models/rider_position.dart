import 'package:latlong2/latlong.dart';

/// A rider's live location, as read from the Realtime Database.
class RiderPosition {
  const RiderPosition({
    required this.riderId,
    required this.location,
    required this.isOnline,
  });

  final String riderId;
  final LatLng location;
  final bool isOnline;
}
