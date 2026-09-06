/// A ride's lifecycle state.
enum RideStatus { active, ended }

/// A ride, as returned by the Cloud Run backend.
class Ride {
  const Ride({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.hostId,
    required this.status,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      hostId: json['hostId'] as String,
      status: RideStatus.values.byName(json['status'] as String),
    );
  }

  final String id;
  final String name;
  final String inviteCode;
  final String hostId;
  final RideStatus status;
}
