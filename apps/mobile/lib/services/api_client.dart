import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_service.dart';

/// Base URL of the deployed Cloud Run backend, used for release/profile
/// builds — override per-build with `--dart-define=RAA_PODHAM_API_BASE_URL=...`.
const String _defaultApiBaseUrl = 'https://api.raapodham.example.com';

/// Debug builds always hit the locally-run backend instead — on a real
/// Android device (not an emulator) this needs `adb reverse tcp:8080
/// tcp:8080` first, so the device's own "localhost" reaches the dev
/// machine. (An Android emulator would use 10.0.2.2 instead; iOS
/// Simulator can use localhost directly.)
const String _localApiBaseUrl = 'http://localhost:8080';

String get _resolvedApiBaseUrl {
  if (kDebugMode) return _localApiBaseUrl;
  return const String.fromEnvironment(
    'RAA_PODHAM_API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
}

/// Thin Dio wrapper for the Cloud Run backend — the only place that
/// should import `package:dio` outside of this file. Attaches the
/// signed-in user's Firebase ID token as a Bearer header on every
/// request.
class ApiClient {
  ApiClient(this._authService, {Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: _resolvedApiBaseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode)
            print('API REQUEST: ${options.method} ${options.uri}');
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            // TEMPORARY debug instrumentation — remove before committing.
            // Android truncates a single print() at ~1024 chars, which
            // silently corrupts anything longer (like this token) — so
            // this prints it in small, individually-tagged chunks
            // instead of one long line.
            if (kDebugMode) {
              const chunkSize = 200;
              for (var i = 0; i < token.length; i += chunkSize) {
                final end = (i + chunkSize < token.length)
                    ? i + chunkSize
                    : token.length;
                print(
                  'DEBUG_BEARER_TOKEN_CHUNK[$i]: ${token.substring(i, end)}',
                );
              }
              print('DEBUG_BEARER_TOKEN_END length=${token.length}');
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final FirebaseAuthService _authService;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);
}
