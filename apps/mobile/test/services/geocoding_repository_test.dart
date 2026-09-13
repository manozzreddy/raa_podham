// Unit tests for GeocodingRepository's mapping of the backend's
// `/places/*` responses, against a fake Dio adapter wired through
// ApiClient — never hits the real backend or Google.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raa_podham/services/api_client.dart';
import 'package:raa_podham/services/firebase_auth_service.dart';
import 'package:raa_podham/services/geocoding_repository.dart';

class _FakeFirebaseAuthService implements FirebaseAuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithApple() => throw UnimplementedError();
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responseData);

  final Map<String, dynamic> responseData;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

GeocodingRepository _repositoryReturning(Map<String, dynamic> responseData) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.httpClientAdapter = _FakeAdapter(responseData);
  final apiClient = ApiClient(_FakeFirebaseAuthService(), dio: dio);
  return GeocodingRepository(apiClient);
}

void main() {
  group('autocomplete', () {
    test('maps the backend\'s /places/autocomplete response', () async {
      final repository = _repositoryReturning({
        'predictions': [
          {
            'placeId': 'place-1',
            'displayName': 'Cubbon Park',
            'secondaryText': 'Kasturba Road, Bengaluru, Karnataka, India',
          },
        ],
      });

      final results = await repository.autocomplete('cubbon park');

      expect(results, hasLength(1));
      expect(results.single.placeId, 'place-1');
      expect(results.single.displayName, 'Cubbon Park');
      expect(
        results.single.secondaryText,
        'Kasturba Road, Bengaluru, Karnataka, India',
      );
    });

    test('returns an empty list for an empty predictions response', () async {
      final repository = _repositoryReturning(const {'predictions': []});

      final results = await repository.autocomplete(
        'somewhere with no matches',
      );

      expect(results, isEmpty);
    });
  });

  group('resolvePlace', () {
    test('maps the backend\'s /places/details response', () async {
      final repository = _repositoryReturning({'lat': 12.9716, 'lng': 77.5946});

      final result = await repository.resolvePlace(
        const DestinationPrediction(
          placeId: 'place-1',
          displayName: 'Cubbon Park',
          secondaryText: 'Bengaluru, Karnataka, India',
        ),
      );

      expect(result.displayName, 'Cubbon Park');
      expect(result.secondaryText, 'Bengaluru, Karnataka, India');
      expect(result.lat, 12.9716);
      expect(result.lng, 77.5946);
    });
  });
}
