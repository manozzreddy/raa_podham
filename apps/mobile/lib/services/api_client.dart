import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'firebase_auth_service.dart';

/// Base URL of the deployed Cloud Run backend — the default for
/// release/profile builds.
const String _defaultApiBaseUrl = 'https://raa-podham-api-vf6ipdg7dq-el.a.run.app';

/// Debug builds hit the locally-run backend by default instead. Set to
/// the dev machine's LAN IP (not "localhost") so a physical device on
/// the same Wi-Fi can reach it — "localhost" from the device's own
/// perspective means the device itself, not this machine. The backend
/// already binds to all interfaces (see internal/config's HOST var), so
/// nothing on that side needs to change if this IP does; re-check it
/// with `ipconfig` if the dev machine reconnects to a different network.
const String _localApiBaseUrl = 'http://192.168.1.100:8080';

/// Flip to true to make a debug build hit the deployed backend instead
/// of the local one — e.g. to test against real data without running
/// the backend yourself. Leave false for the normal local dev loop.
const bool _debugUseDeployedBackend = true;

String get _resolvedApiBaseUrl {
  if (!kDebugMode) return _defaultApiBaseUrl;
  return _debugUseDeployedBackend ? _defaultApiBaseUrl : _localApiBaseUrl;
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
          if (kDebugMode) {
            print('API REQUEST: ${options.method} ${options.uri}');
          }
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
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
