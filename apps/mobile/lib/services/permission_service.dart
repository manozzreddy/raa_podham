import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service.g.dart';

/// Where the device's "while using the app" location permission stands
/// right now. `permission_handler`'s own [PermissionStatus] is wider than
/// this app needs and doesn't say which recovery UI applies, so this
/// collapses it to the three outcomes [LocationPermissionScreen] actually
/// branches on: fine, ask again, or send them to Settings.
enum LocationPermissionStatus {
  granted,

  /// Not granted yet, but asking again would still show the OS prompt.
  denied,

  /// Asking again would no longer show the OS prompt (Android's "don't
  /// ask again", or iOS after an explicit decline) — the only way back
  /// in is the device's own Settings app.
  permanentlyDenied,
}

/// Every OS permission Raa Podham asks for, in the two tiers the app
/// actually treats differently:
///  - **When-in-use location** — mandatory. [LocationPermissionScreen]
///    gates `/home` on it, and the router's own redirect re-checks it on
///    every navigation (see `app.dart`).
///  - **Background sharing** — background location, the foreground-
///    service notification, and the battery-optimization exemption.
///    Optional: a rider who skips them still reports normally while the
///    app is in the foreground (see `device_location.dart`'s
///    `watchCurrentPosition`), so nothing here ever blocks anything. See
///    [BackgroundSharingPermissionScreen].
class PermissionService {
  Future<LocationPermissionStatus> locationWhenInUseStatus() async =>
      _mapLocationStatus(await Permission.locationWhenInUse.status);

  Future<LocationPermissionStatus> requestLocationWhenInUse() async =>
      _mapLocationStatus(await Permission.locationWhenInUse.request());

  Future<bool> isLocationWhenInUseGranted() => Permission.locationWhenInUse.isGranted;

  Future<void> openSettings() => openAppSettings();

  /// True once there's nothing left worth prompting for: background
  /// location granted, and — Android only, since the other two don't
  /// apply on iOS — the notification and battery-optimization asks
  /// resolved too.
  Future<bool> isBackgroundSharingSatisfied() async {
    if (!await Permission.locationAlways.isGranted) return false;
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted &&
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Requests all three in turn, each independent of the others'
  /// outcome — a decline on one is never treated as a reason to skip
  /// asking about the next.
  Future<void> requestBackgroundSharing() async {
    await Permission.locationAlways.request();
    if (!Platform.isAndroid) return;
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  LocationPermissionStatus _mapLocationStatus(PermissionStatus status) {
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (status.isGranted || status.isLimited) return LocationPermissionStatus.granted;
    return LocationPermissionStatus.denied;
  }
}

@Riverpod(keepAlive: true)
PermissionService permissionService(Ref ref) => PermissionService();
