import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/permission_service.dart';
import '../../../services/routes_repository.dart';
import '../../home/data/device_location.dart';
import '../models/ride.dart';

part 'ride_route_info.g.dart';

/// The rider's own real-road distance/duration to [ride]'s destination —
/// the same [RoutesRepository] call `HomeViewModel` already makes for an
/// active ride's own ETA, reused here for `RideDetailScreen`'s upcoming-
/// ride preview. Null if there's no destination to route to, or if the
/// device's position isn't available (permission denied, location
/// services off) — never fatal to the rest of the screen, which stands
/// on its own without this.
@riverpod
Future<RouteInfo?> rideRouteInfo(Ref ref, Ride ride) async {
  final destination = ride.destination;
  if (destination == null) return null;

  final position = await acquireCurrentPosition(
    permissionService: ref.watch(permissionServiceProvider),
  );
  if (position == null) return null;

  return ref
      .watch(routesRepositoryProvider)
      .computeRoute(
        origin: LatLng(position.latitude, position.longitude),
        destination: LatLng(destination.lat, destination.lng),
      );
}
