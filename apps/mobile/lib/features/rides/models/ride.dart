/// A ride's lifecycle state.
enum RideStatus { active, scheduled, ended }

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
    this.scheduledAt,
    this.notes,
    this.coverPhotoUrl,
    required this.createdAt,
    this.endedAt,
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
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
    );
  }

  final String id;
  final String name;
  final String inviteCode;
  final String hostId;
  final RideStatus status;
  final RideDestination? destination;

  /// When the ride is meant to start, if the host scheduled it for later
  /// rather than starting it right away — null means it started
  /// immediately on creation. Always in the past once [status] has moved
  /// on from [RideStatus.scheduled].
  final DateTime? scheduledAt;

  /// Free-text notes the host added at creation — meeting details, what
  /// to bring, and similar. Null/empty means none were added.
  final String? notes;

  /// A cover photo the host picked at creation, already uploaded to
  /// Firebase Storage — null means none was picked.
  final String? coverPhotoUrl;

  final DateTime createdAt;

  /// When the ride was ended — null unless [status] is
  /// [RideStatus.ended]. Used to sort/label a past ride in
  /// `PastRidesScreen`, since [createdAt] alone would be when it was
  /// created, not when it actually finished.
  final DateTime? endedAt;

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
          other.destination == destination &&
          other.scheduledAt == scheduledAt &&
          other.notes == notes &&
          other.coverPhotoUrl == coverPhotoUrl &&
          other.createdAt == createdAt &&
          other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    inviteCode,
    hostId,
    status,
    destination,
    scheduledAt,
    notes,
    coverPhotoUrl,
    createdAt,
    endedAt,
  );
}

const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// E.g. "Sun, Sep 20 · 6:30 AM" — the one place a ride's [Ride.scheduledAt]
/// gets formatted for display, shared by the create-ride form's own picker
/// and the upcoming-ride card/detail sheet, so the wording never drifts
/// between them. Hand-rolled rather than pulling in `intl`: this app does
/// no other i18n/localized formatting anywhere.
String formatScheduledTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final weekday = _weekdayAbbr[local.weekday - 1];
  final month = _monthAbbr[local.month - 1];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$weekday, $month ${local.day} · $hour12:$minute $period';
}

/// E.g. "Sep 10, 2026" — a past ride's ended (or created, if it somehow
/// has no `endedAt`) date, for `PastRidesScreen`'s list. Includes the
/// year, unlike [formatScheduledTime]: an upcoming ride is always within
/// the next year, but a past one could be from any year.
String formatPastDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = _monthAbbr[local.month - 1];
  return '$month ${local.day}, ${local.year}';
}

/// The full share message — shared by `HomeViewModel.inviteMore` and
/// `ShareInviteScreen` so both entry points send identical wording.
///
/// Leads with the invite code rather than a `rapodham://` link: no URL
/// scheme is registered on either platform, so a link would render as a
/// dead hyperlink in WhatsApp and most other share targets.
String buildInviteMessage(Ride ride) =>
    'Join my ride on Raa Podham. Use invite code ${ride.inviteCode} to join.';
