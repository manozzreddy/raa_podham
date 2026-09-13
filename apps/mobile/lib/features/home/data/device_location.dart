import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
