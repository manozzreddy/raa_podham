import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

import '../../../services/permission_service.dart';

/// Requests location permission (if needed) and returns the device's
/// current position, or null if permission/location services aren't
/// available.
///
/// Shared by [HomeViewModel] and [NoActiveRideViewModel] — both resolve
/// the device's own position the same way, whether or not there's a ride
/// to merge it with. Takes [permissionService] rather than reading
/// `permission_handler` directly — [PermissionService] is the only class
/// that should import that package, the same rule this codebase already
/// applies to Firestore/dio in `data/` repositories.
Future<Position?> acquireCurrentPosition({
  required PermissionService permissionService,
}) async {
  try {
    final status = await permissionService.requestLocationWhenInUse();
    if (status != LocationPermissionStatus.granted) return null;
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  } catch (_) {
    // Permission plugins/location services can fail in ways specific to
    // the device (or be entirely unavailable, as in widget tests); fall
    // back to fallbackSelfLocation rather than taking the screen down.
    return null;
  }
}

/// The minimum time between [watchCurrentPosition] updates, even if the
/// device keeps moving past `distanceFilter` well within that window
/// (easy at riding speed — 10m goes by in ~1s at 40 km/h). Without this,
/// a fast-moving rider could report — and write to RTDB — several times
/// a second; a shared group map has no need for sub-5-second precision.
const _minReportInterval = Duration(seconds: 5);

/// Fixes worse than this (meters) are dropped rather than reported —
/// typical of a degraded/network-only fix (poor GPS visibility, indoors,
/// urban canyon) rather than the rider's real position. Reporting one
/// would jump their marker to a wrong spot for the rest of the group, and
/// since it'd likely differ from the last good fix by more than
/// `distanceFilter`, it wouldn't otherwise get filtered out upstream.
const _maxAcceptableAccuracy = 50.0;

/// A live stream of the device's position while it changes, for
/// [HomeViewModel] to report to a ride's RTDB positions node while it's
/// active. Yields nothing (no error) if permission/location services
/// aren't available — same fallback as [acquireCurrentPosition], so a
/// caller can just listen without its own permission handling.
///
/// Gated by distance, time, and accuracy: `distanceFilter` (native, so
/// the OS itself skips notifying Dart for jitter under 10m),
/// [_minReportInterval] (Dart-side, since distanceFilter alone doesn't
/// bound how often two 10m-apart updates can arrive), and
/// [_maxAcceptableAccuracy] (Dart-side, dropping degraded fixes that
/// would otherwise report a wrong position to the rest of the group).
///
/// Runs as a foreground service (Android) / with background updates
/// enabled (iOS) via [_platformLocationSettings], so this keeps
/// reporting once the app is backgrounded — not just while it's the
/// foreground activity, which is all a plain [LocationSettings] stream
/// would otherwise manage. A granted "always" permission is what that
/// actually depends on; a user who only has "while in use" still gets
/// everything working normally in the foreground, they just drop off the
/// map for everyone else once they background the app.
///
/// Doesn't request "always"/notification/battery-optimization itself —
/// by the time this runs, [HomeViewModel] has already routed through
/// [BackgroundSharingPermissionScreen], which is what asks for those
/// (with an explanation) or the rider explicitly skipped it. Prompting
/// again here would either double up the OS dialog right after they just
/// answered it, or ask cold for someone who chose to skip.
Stream<Position> watchCurrentPosition({
  required PermissionService permissionService,
}) async* {
  try {
    if (!await permissionService.isLocationWhenInUseGranted()) return;
    if (!await Geolocator.isLocationServiceEnabled()) return;

    DateTime? lastReportedAt;
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _platformLocationSettings(),
    )) {
      if (position.accuracy > _maxAcceptableAccuracy) continue;
      final now = DateTime.now();
      if (lastReportedAt != null &&
          now.difference(lastReportedAt) < _minReportInterval) {
        continue;
      }
      lastReportedAt = now;
      yield position;
    }
  } catch (_) {
    // See acquireCurrentPosition's catch above — same reasoning.
  }
}

/// The persistent notification Android requires while a location-type
/// foreground service is running — not cosmetic, the service (and so
/// background reporting) doesn't run without one.
///
/// Spells out what swiping it away actually does (stops the foreground
/// service, so this rider stops reporting), since Android 13+ always
/// lets a rider dismiss it — see watchCurrentPosition's own doc comment
/// — and a bare "sharing your location" text wouldn't tip anyone off
/// that dismissing it isn't a no-op the way it is for most notifications.
const _foregroundNotificationTitle = 'Raa Podham';
const _foregroundNotificationText =
    'Sharing your location with your ride group. Dismiss this to stop.';

LocationSettings _platformLocationSettings() {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: _foregroundNotificationTitle,
        notificationText: _foregroundNotificationText,
        setOngoing: true,
      ),
    );
  }
  if (Platform.isIOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      allowBackgroundLocationUpdates: true,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  }
  return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
}

/// Whether location is currently usable at all — permission granted
/// *and* the device's location-services toggle on. Checked once (not
/// streamed): Android/iOS don't offer a live callback for permission
/// changes the way [watchLocationServicesEnabled] gets for the services
/// toggle below, so this is meant to be (re-)checked at a natural point
/// (screen build, coming back from Settings) rather than watched
/// continuously.
Future<bool> isLocationAvailable({
  required PermissionService permissionService,
}) async {
  if (!await permissionService.isLocationWhenInUseGranted()) return false;
  return Geolocator.isLocationServiceEnabled();
}

/// Live updates whenever the device's location-services toggle flips —
/// lets [HomeViewModel] recover automatically, with no app restart
/// needed, once a rider turns location back on after being warned they
/// were invisible to the rest of the group.
Stream<bool> watchLocationServicesEnabled() {
  return Geolocator.getServiceStatusStream().map(
    (status) => status == ServiceStatus.enabled,
  );
}
