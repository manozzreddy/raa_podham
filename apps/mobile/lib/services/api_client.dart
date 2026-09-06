import 'package:dio/dio.dart';

import 'firebase_auth_service.dart';

/// Base URL of the Cloud Run backend. No backend is deployed yet — replace
/// this once one exists, or override it per-build with
/// `--dart-define=RAA_PODHAM_API_BASE_URL=...`.
const String _defaultApiBaseUrl = 'https://api.raapodham.example.com';

/// Thin Dio wrapper for the Cloud Run backend — the only place that
/// should import `package:dio` outside of this file. Attaches the
/// signed-in user's Firebase ID token as a Bearer header on every
/// request.
class ApiClient {
  ApiClient(this._authService, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: const String.fromEnvironment(
                  'RAA_PODHAM_API_BASE_URL',
                  defaultValue: _defaultApiBaseUrl,
                ),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) => _dio.post<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) => _dio.delete<T>(path, data: data);
}
