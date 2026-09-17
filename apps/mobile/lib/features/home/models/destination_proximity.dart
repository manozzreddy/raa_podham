import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../rides/models/ride.dart';

/// How close a rider's live position must be to the ride's destination pin
/// to count as "reached" — generous enough to absorb ordinary GPS drift
/// (see `_maxAcceptableAccuracy` in `device_location.dart`) without
/// requiring someone to stand exactly on the pin.
const double reachedDestinationRadiusMeters = 75;

/// Whether [location] currently counts as "at" [destination] — recomputed
/// live from whatever position is on hand, the same way `Rider.isOnline`/
/// `HomeViewModel`'s distance labels are, rather than a value fixed once
/// and stored.
bool isNearDestination(LatLng location, RideDestination destination) {
  final distanceMeters = Geolocator.distanceBetween(
    location.latitude,
    location.longitude,
    destination.lat,
    destination.lng,
  );
  return distanceMeters <= reachedDestinationRadiusMeters;
}
