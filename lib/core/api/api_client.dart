import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// HTTP client wrapper menggunakan Dio untuk komunikasi ke backend.
///
/// Konfigurasi:
/// - Base URL: `http://16.79.51.70:3000` (Deployed backend)
/// - Headers: Content-Type & Accept = `application/json`
/// - Connect timeout: 30 detik
/// - Receive timeout: 30 detik
/// - JWT interceptor: auto-attach token & auto-refresh on 401
class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;

  ApiClient({required SecureStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://16.79.51.70:3000',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.contains('/api/auth/');
          final isPasswordEndpoint = path.contains('/api/me/password');

          if (error.response?.statusCode == 401 &&
              !isAuthEndpoint &&
              !isPasswordEndpoint) {
            try {
              final refreshToken = await _storage.getRefreshToken();
              if (refreshToken == null) {
                return handler.next(error);
              }

              // Gunakan Dio instance terpisah untuk refresh (hindari interceptor loop)
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: 'http://16.79.51.70:3000',
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final response = await refreshDio.post(
                '/api/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final newAccess =
                  response.data['data']['accessToken'] as String;
              final newRefresh =
                  response.data['data']['refreshToken'] as String;

              // Simpan token baru
              await _storage.saveAccessToken(newAccess);
              await _storage.saveRefreshToken(newRefresh);

              // Retry original request dengan token baru
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await _dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (e) {
              // Refresh gagal → clear semua token
              await _storage.clearAll();
              return handler.next(error);
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Dio instance untuk digunakan oleh providers.
  Dio get dio => _dio;

  /// SecureStorage instance (digunakan oleh interceptor).
  SecureStorage get storage => _storage;
}
