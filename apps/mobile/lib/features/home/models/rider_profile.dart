/// A rider's profile info, as read from the ride's Firestore membership
/// document.
class RiderProfile {
  const RiderProfile({required this.riderId, required this.displayName});

  final String riderId;
  final String displayName;
}
