import 'package:latlong2/latlong.dart';

import 'rider_position.dart';
import 'rider_profile.dart';

/// How long a position can go without a fresh write before its rider
/// reads as offline, even though nobody explicitly marked them so. Well
/// above the 5s/10m reporting cadence (`watchCurrentPosition`), so a
/// rider isn't flickering offline between ordinary updates; well below
/// "clearly abandoned," so a rider who's actually still connected but
/// silently stuck (GPS failing without disconnecting, say) doesn't read
/// as present indefinitely the way a raw `isOnline` flag alone would.
const staleRiderThreshold = Duration(minutes: 2);

/// A group member ready to render: [RiderPosition] (Realtime Database)
/// merged with [RiderProfile] (Firestore membership), plus whether this
/// rider is the signed-in user.
class Rider {
  const Rider({
    required this.riderId,
    required this.displayName,
    this.photoUrl,
    required this.location,
    required bool rawIsOnline,
    required this.updatedAt,
    required this.isSelf,
  }) : _rawIsOnline = rawIsOnline;

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
      rawIsOnline: position.isOnline,
      updatedAt: position.updatedAt,
      isSelf: position.riderId == currentUserId,
    );
  }

  // Kept as a plain constructor parameter (rawIsOnline) rather than
  // `this._rawIsOnline`: the latter would make the parameter name itself
  // private, which happens to still work today since Rider.merge is the
  // only call site and it's in this same file, but would silently break
  // the moment any other file needed to construct a Rider directly.

  final String riderId;
  final String displayName;
  final String? photoUrl;
  final LatLng location;
  final bool isSelf;

  /// When this rider's position was last written.
  final DateTime updatedAt;

  /// RTDB's own flag — normally true, flipped false server-side by
  /// `onDisconnect` if this rider's app disconnects ungracefully.
  final bool _rawIsOnline;

  /// A getter, not a value fixed at merge time, so it re-evaluates
  /// against the current time on every read — including from
  /// HomeViewModel's periodic staleness recheck, which re-publishes
  /// state without any new data having arrived at all. Combines the raw
  /// flag with [staleRiderThreshold] to also catch a rider who's still
  /// connected but has silently stopped actually updating.
  bool get isOnline =>
      _rawIsOnline && DateTime.now().difference(updatedAt) <= staleRiderThreshold;
}
