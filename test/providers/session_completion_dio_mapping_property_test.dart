// Feature: tahap-7-session-completion, Property 7: DioException to AppException Mapping

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/errors/app_exception.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/models/session_model.dart';
import 'package:sinicerita/models/user_model.dart';
import 'package:sinicerita/providers/auth_provider.dart';
import 'package:sinicerita/providers/session_provider.dart';

/// **Validates: Requirements 2.7**
///
/// Property 7: DioException to AppException Mapping
///
/// For any DioExceptionType, verify `AppException.fromDioError()` produces
/// a non-empty error message string that is then exposed via
/// `SessionProvider.errorMessage`.

// ─── Manual Mocks ─────────────────────────────────────────────────────────────

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

/// Creates a Dio instance that throws the given [DioException] on PATCH requests.
Dio _createFailingDio(DioException exception) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            type: exception.type,
            requestOptions: options,
            response: exception.response,
            message: exception.message,
          ),
        );
      },
    ),
  );
  return dio;
}

/// Creates a SessionProvider with a Dio that always throws the given exception.
SessionProvider _createFailingProvider(DioException exception) {
  final dio = _createFailingDio(exception);
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return SessionProvider(apiClient: mockApiClient);
}

/// Creates a Dio that returns a successful login response for AuthProvider.
Dio _createAuthDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'message': 'OK',
              'data': {
                'id': 'user-1',
                'name': 'Test User',
                'email': 'test@example.com',
                'role': 'user',
                'points': 50,
                'avatarUrl': null,
                'createdAt': '2024-01-01T00:00:00.000Z',
              },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

/// Creates an AuthProvider with a mock user already set.
AuthProvider _createAuthProvider() {
  final dio = _createAuthDio();
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return AuthProvider(apiClient: mockApiClient);
}

// ─── Property Tests ───────────────────────────────────────────────────────────

void main() {
  group('Property 7: DioException to AppException Mapping', () {
    /// All DioExceptionType values to iterate over.
    const allDioExceptionTypes = DioExceptionType.values;

    /// Status codes to test for badResponse type.
    const badResponseStatusCodes = [400, 401, 403, 404, 409, 500];

    late AuthProvider authProvider;

    setUp(() async {
      authProvider = _createAuthProvider();
      // Simulate authenticated state by calling checkAuthStatus
      await authProvider.checkAuthStatus();
    });

    test(
      'For ALL DioExceptionType values, AppException.fromDioError() produces '
      'non-empty errorMessage exposed via SessionProvider.errorMessage',
      () async {
        for (final type in allDioExceptionTypes) {
          final requestOptions = RequestOptions(
            path: '/api/sessions/test-session-id/complete',
            method: 'PATCH',
          );

          DioException dioException;
          if (type == DioExceptionType.badResponse) {
            // For badResponse, test with a generic status code first
            dioException = DioException(
              type: type,
              requestOptions: requestOptions,
              response: Response(
                requestOptions: requestOptions,
                statusCode: 500,
                data: {'success': false, 'message': 'Server error'},
              ),
            );
          } else {
            dioException = DioException(
              type: type,
              requestOptions: requestOptions,
              message: 'Simulated ${type.name} error',
            );
          }

          // Verify AppException.fromDioError directly
          final appException = AppException.fromDioError(dioException);
          expect(
            appException.message,
            isNotNull,
            reason: 'AppException.fromDioError for ${type.name} should '
                'produce non-null message',
          );
          expect(
            appException.message.isNotEmpty,
            isTrue,
            reason: 'AppException.fromDioError for ${type.name} should '
                'produce non-empty message. Got: "${appException.message}"',
          );

          // Verify through SessionProvider.completeSession
          final provider = _createFailingProvider(dioException);
          final result = await provider.completeSession(
            'test-session-id',
            authProvider,
          );

          expect(
            result,
            isNull,
            reason: '${type.name}: completeSession should return null on failure',
          );
          expect(
            provider.errorMessage,
            isNotNull,
            reason: '${type.name}: errorMessage should be non-null after '
                'DioException',
          );
          expect(
            provider.errorMessage!.isNotEmpty,
            isTrue,
            reason: '${type.name}: errorMessage should be non-empty after '
                'DioException. Got: "${provider.errorMessage}"',
          );
        }
      },
    );

    test(
      'For badResponse type with various status codes (400, 401, 403, 404, 409, 500), '
      'AppException.fromDioError() produces non-empty errorMessage',
      () async {
        for (final statusCode in badResponseStatusCodes) {
          final requestOptions = RequestOptions(
            path: '/api/sessions/test-session-id/complete',
            method: 'PATCH',
          );

          // Test with backend message in response
          final dioExceptionWithMessage = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {
                'success': false,
                'message': 'Error message for status $statusCode',
              },
            ),
          );

          final provider1 = _createFailingProvider(dioExceptionWithMessage);
          final result1 = await provider1.completeSession(
            'test-session-id',
            authProvider,
          );

          expect(
            result1,
            isNull,
            reason: 'badResponse $statusCode (with message): '
                'completeSession should return null',
          );
          expect(
            provider1.errorMessage,
            isNotNull,
            reason: 'badResponse $statusCode (with message): '
                'errorMessage should be non-null',
          );
          expect(
            provider1.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'badResponse $statusCode (with message): '
                'errorMessage should be non-empty. '
                'Got: "${provider1.errorMessage}"',
          );

          // Test without backend message in response (fallback to status code message)
          final dioExceptionWithoutMessage = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {'success': false},
            ),
          );

          final provider2 = _createFailingProvider(dioExceptionWithoutMessage);
          final result2 = await provider2.completeSession(
            'test-session-id',
            authProvider,
          );

          expect(
            result2,
            isNull,
            reason: 'badResponse $statusCode (without message): '
                'completeSession should return null',
          );
          expect(
            provider2.errorMessage,
            isNotNull,
            reason: 'badResponse $statusCode (without message): '
                'errorMessage should be non-null',
          );
          expect(
            provider2.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'badResponse $statusCode (without message): '
                'errorMessage should be non-empty. '
                'Got: "${provider2.errorMessage}"',
          );
        }
      },
    );

    test(
      'Property holds across 100 random iterations with random DioExceptionTypes '
      'and random status codes for badResponse',
      () async {
        const int iterations = 100;
        final random = Random(42);

        for (var i = 0; i < iterations; i++) {
          final type = allDioExceptionTypes[
              random.nextInt(allDioExceptionTypes.length)];
          final requestOptions = RequestOptions(
            path: '/api/sessions/session-$i/complete',
            method: 'PATCH',
          );

          DioException dioException;
          if (type == DioExceptionType.badResponse) {
            final statusCode = badResponseStatusCodes[
                random.nextInt(badResponseStatusCodes.length)];
            final hasMessage = random.nextBool();
            final responseData = hasMessage
                ? {
                    'success': false,
                    'message': 'Random error message iteration $i',
                  }
                : {'success': false};

            dioException = DioException(
              type: type,
              requestOptions: requestOptions,
              response: Response(
                requestOptions: requestOptions,
                statusCode: statusCode,
                data: responseData,
              ),
            );
          } else {
            dioException = DioException(
              type: type,
              requestOptions: requestOptions,
              message: 'Simulated ${type.name} error iteration $i',
            );
          }

          // Verify AppException.fromDioError directly
          final appException = AppException.fromDioError(dioException);
          expect(
            appException.message.isNotEmpty,
            isTrue,
            reason: 'Iteration $i (${type.name}): AppException.message '
                'should be non-empty',
          );

          // Verify through SessionProvider
          final provider = _createFailingProvider(dioException);
          final result = await provider.completeSession(
            'session-$i',
            authProvider,
          );

          expect(
            result,
            isNull,
            reason: 'Iteration $i (${type.name}): completeSession should '
                'return null on failure',
          );
          expect(
            provider.errorMessage,
            isNotNull,
            reason: 'Iteration $i (${type.name}): errorMessage should be '
                'non-null',
          );
          expect(
            provider.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'Iteration $i (${type.name}): errorMessage should be '
                'non-empty. Got: "${provider.errorMessage}"',
          );
        }
      },
    );

    test(
      'Non-badResponse DioExceptionTypes produce known AppException messages',
      () async {
        final typeToExpectedMessage = {
          DioExceptionType.connectionTimeout:
              'Koneksi timeout. Periksa jaringan Anda.',
          DioExceptionType.receiveTimeout:
              'Server tidak merespons. Coba lagi nanti.',
          DioExceptionType.connectionError:
              'Tidak dapat terhubung ke server.',
          DioExceptionType.sendTimeout:
              'Terjadi kesalahan. Coba lagi nanti.',
          DioExceptionType.cancel:
              'Terjadi kesalahan. Coba lagi nanti.',
          DioExceptionType.badCertificate:
              'Terjadi kesalahan. Coba lagi nanti.',
          DioExceptionType.unknown:
              'Terjadi kesalahan. Coba lagi nanti.',
        };

        for (final entry in typeToExpectedMessage.entries) {
          final type = entry.key;
          final expectedMessage = entry.value;

          final requestOptions = RequestOptions(
            path: '/api/sessions/test-session/complete',
            method: 'PATCH',
          );

          final dioException = DioException(
            type: type,
            requestOptions: requestOptions,
            message: 'Simulated ${type.name} error',
          );

          // Verify AppException directly
          final appException = AppException.fromDioError(dioException);
          expect(
            appException.message,
            equals(expectedMessage),
            reason: '${type.name}: AppException.message should be '
                '"$expectedMessage". Got: "${appException.message}"',
          );

          // Verify through SessionProvider
          final provider = _createFailingProvider(dioException);
          final result = await provider.completeSession(
            'test-session',
            authProvider,
          );

          expect(result, isNull);
          expect(
            provider.errorMessage,
            equals(expectedMessage),
            reason: '${type.name}: SessionProvider.errorMessage should be '
                '"$expectedMessage". Got: "${provider.errorMessage}"',
          );
          expect(
            provider.errorMessage!.isNotEmpty,
            isTrue,
            reason: '${type.name}: errorMessage should be non-empty',
          );
        }
      },
    );
  });
}
