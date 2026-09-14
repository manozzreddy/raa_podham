import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'providers.dart';

part 'routes_repository.g.dart';

/// A computed route between two points — distance, duration, and the
/// path itself, ready to draw as a polyline.
class RouteInfo {
  const RouteInfo({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });

  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> points;
}

/// Talks to the Cloud Run backend's `/routes` endpoint
/// (`internal/handler/routes_handler.go`), which proxies Google's Routes
/// API on the server side — same reasoning as [GeocodingRepository]: the
/// real Google API key lives only in the backend and never ships inside
/// this app.
class RoutesRepository {
  RoutesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<RouteInfo> computeRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/routes',
      queryParameters: {
        'originLat': origin.latitude,
        'originLng': origin.longitude,
        'destLat': destination.latitude,
        'destLng': destination.longitude,
      },
    );
    final data = response.data!;
    return RouteInfo(
      distanceMeters: data['distanceMeters'] as int,
      durationSeconds: data['durationSeconds'] as int,
      points: decodePolyline(data['polyline'] as String),
    );
  }
}

/// Decodes a Google Maps encoded polyline into the points it represents.
/// Standard algorithm — see
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

@riverpod
RoutesRepository routesRepository(Ref ref) =>
    RoutesRepository(ref.watch(apiClientProvider));
