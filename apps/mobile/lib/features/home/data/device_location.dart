import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
// ServiceStatus exists in both packages; we mean geolocator's (location
// services on/off), not permission_handler's.
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

/// Requests location permission (if needed) and returns the device's
/// current position, or null if permission/location services aren't
/// available.
///
/// Shared by [HomeViewModel] and [NoActiveRideViewModel] — both resolve
/// the device's own position the same way, whether or not there's a ride
/// to merge it with.
Future<Position?> acquireCurrentPosition() async {
  try {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) return null;
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

/// A live stream of the device's position while it changes, for
/// [HomeViewModel] to report to a ride's RTDB positions node while it's
/// active. Yields nothing (no error) if permission/location services
/// aren't available — same fallback as [acquireCurrentPosition], so a
/// caller can just listen without its own permission handling.
///
/// Gated by *both* distance and time: `distanceFilter` (native, so the
/// OS itself skips notifying Dart for jitter under 10m) and
/// [_minReportInterval] (Dart-side, since distanceFilter alone doesn't
/// bound how often two 10m-apart updates can arrive).
///
/// Runs as a foreground service (Android) / with background updates
/// enabled (iOS) via [_platformLocationSettings], so this keeps
/// reporting once the app is backgrounded — not just while it's the
/// foreground activity, which is all a plain [LocationSettings] stream
/// would otherwise manage. Requesting "always" below is what that
/// actually depends on; a user who only grants "while in use" still
/// gets everything working normally in the foreground, they just drop
/// off the map for everyone else once they background the app.
Stream<Position> watchCurrentPosition() async* {
  try {
    await Permission.locationAlways.request();
    // Android 13+ only — a no-op on iOS/older Android (permission_handler
    // reports those as already granted). Without this the foreground
    // service still runs, but its notification silently doesn't show, so
    // a rider gets no indication background sharing is active.
    await Permission.notification.request();
    if (!await Permission.locationWhenInUse.isGranted) return;
    if (!await Geolocator.isLocationServiceEnabled()) return;

    DateTime? lastReportedAt;
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _platformLocationSettings(),
    )) {
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
Future<bool> isLocationAvailable() async {
  final permission = await Permission.locationWhenInUse.status;
  if (!permission.isGranted) return false;
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
