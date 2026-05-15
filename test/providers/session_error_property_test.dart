// Feature: session-detail-completed, Property 6: Error message passthrough integrity

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/errors/app_exception.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/providers/session_provider.dart';

// ─── Manual Mocks ─────────────────────────────────────────────────────────────

/// In-memory mock for SecureStorage.
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<bool> isFirstLaunchCompleted() async => true;

  @override
  Future<void> setFirstLaunchCompleted() async {
    _store['first_launch_completed'] = 'true';
  }

  @override
  Future<String?> getAccessToken() async => _store['access_token'];

  @override
  Future<String?> getRefreshToken() async => _store['refresh_token'];

  @override
  Future<void> saveAccessToken(String token) async {
    _store['access_token'] = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _store['refresh_token'] = token;
  }

  @override
  Future<void> clearAll() async {
    _store.remove('access_token');
    _store.remove('refresh_token');
  }
}

/// Mock ApiClient that accepts a custom Dio instance.
class MockApiClient implements ApiClient {
  final MockSecureStorage _mockStorage;
  final Dio _dio;

  MockApiClient({required MockSecureStorage mockStorage, required Dio dio})
      : _mockStorage = mockStorage,
        _dio = dio;

  @override
  SecureStorage get storage => _mockStorage;

  @override
  Dio get dio => _dio;
}

// ─── Helper Functions ─────────────────────────────────────────────────────────

/// Creates a Dio instance that throws a DioException with badResponse
/// containing the given message on GET /api/sessions/:id.
Dio _createDioWithBadResponse({
  required String errorMessage,
  required int statusCode,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Handle GET /api/sessions/:id → throw badResponse error
        if (options.method == 'GET' &&
            options.path.startsWith('/api/sessions/')) {
          handler.reject(
            DioException(
              type: DioExceptionType.badResponse,
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: statusCode,
                data: {'success': false, 'message': errorMessage},
              ),
            ),
          );
          return;
        }

        // Default: reject unknown requests
        handler.reject(
          DioException(
            type: DioExceptionType.unknown,
            requestOptions: options,
            message: 'Unexpected request: ${options.method} ${options.path}',
          ),
        );
      },
    ),
  );
  return dio;
}

// ─── Test Main ────────────────────────────────────────────────────────────────

void main() {
  // ─── Property 6: Error message passthrough integrity ────────────────────────

  /// **Feature: session-detail-completed, Property 6: Error message passthrough integrity**
  ///
  /// **Validates: Requirements 6.1**
  ///
  /// For any DioException with a badResponse containing a message field,
  /// AppException.fromDioError preserves the exact backend message string,
  /// and the provider exposes this exact string via errorMessage.
  group('Property 6: Error message passthrough integrity', () {
    const int iterations = 120;
    final random = Random(42);

    // ─── Generators ─────────────────────────────────────────────────────────

    /// Generate a random string of given length using printable ASCII chars.
    String generateRandomString(Random rng, int minLength, int maxLength) {
      final length = minLength + rng.nextInt(maxLength - minLength + 1);
      // Use a mix of printable ASCII characters (32-126)
      return String.fromCharCodes(
        List.generate(length, (_) => 32 + rng.nextInt(95)),
      );
    }

    /// Generate a random error message simulating backend messages.
    String generateRandomErrorMessage(Random rng) {
      // Mix of realistic backend messages and random strings
      final predefinedMessages = [
        'Sesi tidak ditemukan',
        'Akses ditolak: sesi bukan milik Anda',
        'Terjadi kesalahan pada server.',
        'Internal server error',
        'Bad request',
        'Unauthorized access',
        'Resource not found',
        'Validation error: field is required',
        'Rate limit exceeded',
        'Service unavailable',
        'Database connection failed',
        'Token expired',
        'Invalid session ID format',
        'Sesi sudah selesai',
        'Persona tidak ditemukan',
        'Koneksi timeout',
      ];

      // 50% chance of predefined message, 50% random string
      if (rng.nextBool()) {
        return predefinedMessages[rng.nextInt(predefinedMessages.length)];
      } else {
        return generateRandomString(rng, 1, 200);
      }
    }

    /// Generate a random HTTP error status code (4xx or 5xx).
    int generateRandomErrorStatusCode(Random rng) {
      final statusCodes = [400, 401, 403, 404, 409, 422, 429, 500, 502, 503];
      return statusCodes[rng.nextInt(statusCodes.length)];
    }

    /// Generate a random session ID.
    String generateRandomSessionId(Random rng) {
      const chars = 'abcdef0123456789';
      return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    }

    // ─── Tests ──────────────────────────────────────────────────────────────

    test(
      'AppException.fromDioError preserves exact backend message for any '
      'badResponse with message field ($iterations random iterations)',
      () {
        for (var i = 0; i < iterations; i++) {
          final errorMessage = generateRandomErrorMessage(random);
          final statusCode = generateRandomErrorStatusCode(random);

          // Create a DioException with badResponse containing the message
          final requestOptions = RequestOptions(
            path: '/api/sessions/test-session-id',
          );
          final dioException = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {'success': false, 'message': errorMessage},
            ),
          );

          // Convert to AppException
          final appException = AppException.fromDioError(dioException);

          // Property: the exact message string is preserved
          expect(
            appException.message,
            equals(errorMessage),
            reason: 'Iteration $i: AppException.message should be '
                '"$errorMessage" (status $statusCode), '
                'got "${appException.message}"',
          );

          // Property: statusCode is preserved
          expect(
            appException.statusCode,
            equals(statusCode),
            reason: 'Iteration $i: AppException.statusCode should be '
                '$statusCode, got ${appException.statusCode}',
          );
        }
      },
    );

    test(
      'SessionProvider.fetchSessionDetail exposes exact backend error message '
      'via errorMessage ($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final errorMessage = generateRandomErrorMessage(random);
          final statusCode = generateRandomErrorStatusCode(random);
          final sessionId = generateRandomSessionId(random);

          // Create mock Dio that returns badResponse with the message
          final dio = _createDioWithBadResponse(
            errorMessage: errorMessage,
            statusCode: statusCode,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          // Call fetchSessionDetail — should fail with the error message
          await sessionProvider.fetchSessionDetail(sessionId);

          // Property: errorMessage is the exact backend message
          expect(
            sessionProvider.errorMessage,
            equals(errorMessage),
            reason: 'Iteration $i: SessionProvider.errorMessage should be '
                '"$errorMessage" (status $statusCode), '
                'got "${sessionProvider.errorMessage}"',
          );

          // Property: isLoadingDetail is false after error
          expect(
            sessionProvider.isLoadingDetail,
            isFalse,
            reason: 'Iteration $i: isLoadingDetail should be false after error',
          );

          // Property: sessionDetail is null after error
          expect(
            sessionProvider.sessionDetail,
            isNull,
            reason: 'Iteration $i: sessionDetail should be null after error',
          );

          // Property: detailPersona is null after error
          expect(
            sessionProvider.detailPersona,
            isNull,
            reason: 'Iteration $i: detailPersona should be null after error',
          );
        }
      },
    );

    test(
      'Error message passthrough works for all common HTTP error status codes',
      () async {
        final statusCodesAndMessages = {
          400: 'Bad request: invalid parameters',
          401: 'Sesi telah berakhir. Silakan login kembali.',
          403: 'Akses ditolak: sesi bukan milik Anda',
          404: 'Sesi tidak ditemukan',
          409: 'Terjadi konflik data.',
          429: 'Too many requests, please try again later',
          500: 'Terjadi kesalahan pada server.',
          502: 'Bad gateway',
          503: 'Service unavailable',
        };

        for (final entry in statusCodesAndMessages.entries) {
          final statusCode = entry.key;
          final message = entry.value;

          // Test AppException.fromDioError directly
          final requestOptions = RequestOptions(
            path: '/api/sessions/test-id',
          );
          final dioException = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {'success': false, 'message': message},
            ),
          );

          final appException = AppException.fromDioError(dioException);
          expect(
            appException.message,
            equals(message),
            reason: 'Status $statusCode: AppException.message should be '
                '"$message", got "${appException.message}"',
          );

          // Test via SessionProvider
          final dio = _createDioWithBadResponse(
            errorMessage: message,
            statusCode: statusCode,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          await sessionProvider.fetchSessionDetail('test-session-id');

          expect(
            sessionProvider.errorMessage,
            equals(message),
            reason: 'Status $statusCode: SessionProvider.errorMessage should '
                'be "$message", got "${sessionProvider.errorMessage}"',
          );
        }
      },
    );

    test(
      'Error messages with special characters are preserved exactly '
      '($iterations random iterations)',
      () async {
        // Test messages with special characters, unicode, etc.
        for (var i = 0; i < iterations; i++) {
          final specialMessages = [
            'Error: field "name" is required',
            "Can't connect to database",
            'Status: 500 — Internal Server Error',
            'Pesan dengan karakter khusus: @#\$%^&*()',
            'Unicode: café, naïve, résumé',
            'Emoji test: ⚠️ Error occurred',
            'Path: /api/sessions/${generateRandomSessionId(random)}',
            'Timestamp: ${DateTime.now().toIso8601String()}',
            'Multi-word error message with spaces and punctuation!',
            'Error code: ERR_${random.nextInt(9999).toString().padLeft(4, '0')}',
          ];

          final message = specialMessages[random.nextInt(specialMessages.length)];
          final statusCode = generateRandomErrorStatusCode(random);

          final requestOptions = RequestOptions(
            path: '/api/sessions/test-id',
          );
          final dioException = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {'success': false, 'message': message},
            ),
          );

          final appException = AppException.fromDioError(dioException);
          expect(
            appException.message,
            equals(message),
            reason: 'Iteration $i: special char message should be preserved '
                'exactly. Expected: "$message", got: "${appException.message}"',
          );

          // Also verify via provider
          final dio = _createDioWithBadResponse(
            errorMessage: message,
            statusCode: statusCode,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          await sessionProvider.fetchSessionDetail('session-${random.nextInt(1000)}');

          expect(
            sessionProvider.errorMessage,
            equals(message),
            reason: 'Iteration $i: provider errorMessage should preserve '
                'special chars. Expected: "$message", '
                'got: "${sessionProvider.errorMessage}"',
          );
        }
      },
    );
  });
}
