import 'package:latlong2/latlong.dart';

/// A rider's live location, as read from the Realtime Database.
class RiderPosition {
  const RiderPosition({
    required this.riderId,
    required this.location,
    required this.isOnline,
    required this.updatedAt,
  });

  final String riderId;
  final LatLng location;

  /// The raw flag from RTDB — normally true, flipped false server-side
  /// by `onDisconnect` if this rider's app disconnects ungracefully.
  /// [Rider.merge] combines this with [updatedAt] to catch the other
  /// failure mode: still connected, but no longer actually updating.
  final bool isOnline;

  /// When this entry was last written, `ServerValue.timestamp` at write
  /// time so it can't be skewed by the reporting device's own clock.
  final DateTime updatedAt;
}
