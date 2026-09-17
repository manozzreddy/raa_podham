import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'providers.dart';

part 'geocoding_repository.g.dart';

/// One Autocomplete (New) prediction — a candidate place, not yet
/// resolved to coordinates. [GeocodingRepository.resolvePlace] turns one
/// of these into a [DestinationSuggestion] once the user actually picks
/// it, via a separate Place Details call.
class DestinationPrediction {
  const DestinationPrediction({
    required this.placeId,
    required this.displayName,
    required this.secondaryText,
    this.distanceMeters,
  });

  final String placeId;

  /// The prediction's most specific name component (e.g. "Cubbon Park").
  final String displayName;

  /// The rest of the prediction's formatted text, for context (e.g.
  /// "Kasturba Road, Bengaluru, Karnataka, India").
  final String secondaryText;

  /// Straight-line distance from the search's origin — null unless
  /// [GeocodingRepository.autocomplete] was called with one (Google only
  /// computes this when an origin is supplied).
  final int? distanceMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinationPrediction &&
          other.placeId == placeId &&
          other.displayName == displayName &&
          other.secondaryText == secondaryText &&
          other.distanceMeters == distanceMeters;

  @override
  int get hashCode =>
      Object.hash(placeId, displayName, secondaryText, distanceMeters);
}

/// A destination fully resolved to coordinates — what the destination
/// search screen actually hands back to [CreateRideViewModel].
class DestinationSuggestion {
  const DestinationSuggestion({
    required this.displayName,
    required this.secondaryText,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final String secondaryText;
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DestinationSuggestion &&
          other.displayName == displayName &&
          other.secondaryText == secondaryText &&
          other.lat == lat &&
          other.lng == lng;

  @override
  int get hashCode => Object.hash(displayName, secondaryText, lat, lng);
}

/// Talks to the Cloud Run backend's `/places/*` endpoints
/// (`internal/handler/places_handler.go`), which proxy Google's Places
/// API (New) on the server side. The real Google API key lives only in
/// the backend's own config/`GooglePlacesRepository` and never ships
/// inside this app, unlike calling Google directly from the client
/// would — so unlike the old Nominatim-backed version of this class,
/// there's no `dio`/key/header setup here at all: it's just another
/// authenticated call through [ApiClient].
class GeocodingRepository {
  GeocodingRepository(this._apiClient);

  final ApiClient _apiClient;

  /// One-shot request — callers (the ViewModel) are responsible for
  /// debouncing so this isn't fired on every keystroke. [origin], when
  /// given, is what each result's [DestinationPrediction.distanceMeters]
  /// ends up measured from.
  Future<List<DestinationPrediction>> autocomplete(
    String query, {
    LatLng? origin,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/places/autocomplete',
      queryParameters: {
        'input': query,
        if (origin != null) 'originLat': origin.latitude,
        if (origin != null) 'originLng': origin.longitude,
      },
    );

    if (kDebugMode) {
      print('API REQUEST RESPONSE: ${response.data}');
    }

    final predictions = response.data?['predictions'] as List<dynamic>? ?? [];
    return predictions
        .cast<Map<String, dynamic>>()
        .map(
          (json) => DestinationPrediction(
            placeId: json['placeId'] as String,
            displayName: json['displayName'] as String? ?? '',
            secondaryText: json['secondaryText'] as String? ?? '',
            distanceMeters: json['distanceMeters'] as int?,
          ),
        )
        .toList(growable: false);
  }

  /// Resolves one prediction's coordinates via the backend's Place
  /// Details proxy.
  Future<DestinationSuggestion> resolvePlace(
    DestinationPrediction prediction,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/places/details',
      queryParameters: {'placeId': prediction.placeId},
    );
    final data = response.data!;
    return DestinationSuggestion(
      displayName: prediction.displayName,
      secondaryText: prediction.secondaryText,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
    );
  }
}

@riverpod
GeocodingRepository geocodingRepository(Ref ref) =>
    GeocodingRepository(ref.watch(apiClientProvider));
