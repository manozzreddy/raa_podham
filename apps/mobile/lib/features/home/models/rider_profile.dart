/// A rider's profile info, as read from the ride's Firestore membership
/// document.
class RiderProfile {
  const RiderProfile({
    required this.riderId,
    required this.displayName,
    this.photoUrl,
  });

  final String riderId;
  final String displayName;

  /// The Google/Apple account photo the backend copied onto this member
  /// doc from `users/{uid}` at join/create time — null for a member who
  /// hadn't written a profile yet.
  final String? photoUrl;
}
