/// A ride's lifecycle state.
enum RideStatus { active, ended }

/// A destination pin shown on the map for everyone in the ride — not a
/// route, just a marker (see `CreateRideScreen`'s own hint text about
/// this to the person creating the ride).
class RideDestination {
  const RideDestination({
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory RideDestination.fromJson(Map<String, dynamic> json) {
    return RideDestination(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  final String name;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideDestination &&
          other.name == name &&
          other.lat == lat &&
          other.lng == lng;

  @override
  int get hashCode => Object.hash(name, lat, lng);
}

/// A ride, as returned by the Cloud Run backend.
class Ride {
  const Ride({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.hostId,
    required this.status,
    this.destination,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      // The backend's field is hostUid (internal/dto/ride_dto.go), not
      // hostId — every ride fetched from a real backend would otherwise
      // throw here.
      hostId: json['hostUid'] as String,
      status: RideStatus.values.byName(json['status'] as String),
      destination: json['destination'] == null
          ? null
          : RideDestination.fromJson(
              json['destination'] as Map<String, dynamic>,
            ),
    );
  }

  final String id;
  final String name;
  final String inviteCode;
  final String hostId;
  final RideStatus status;
  final RideDestination? destination;

  // Value equality so a `Ride` can serve as a Riverpod family key (see
  // homeViewModelProvider) — the default identity equality would treat two
  // fetches of the same ride as different providers.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ride &&
          other.id == id &&
          other.name == name &&
          other.inviteCode == inviteCode &&
          other.hostId == hostId &&
          other.status == status &&
          other.destination == destination;

  @override
  int get hashCode =>
      Object.hash(id, name, inviteCode, hostId, status, destination);
}

/// The full share message — shared by `HomeViewModel.inviteMore` and
/// `ShareInviteScreen` so both entry points send identical wording.
///
/// Leads with the invite code rather than a `rapodham://` link: no URL
/// scheme is registered on either platform, so a link would render as a
/// dead hyperlink in WhatsApp and most other share targets.
String buildInviteMessage(Ride ride) =>
    'Join my ride on Raa Podham. Use invite code ${ride.inviteCode} to join.';
