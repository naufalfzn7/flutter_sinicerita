// Feature: tahap-7-session-completion, Property 5: Error Preservation Invariant

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/models/session_model.dart';
import 'package:sinicerita/models/user_model.dart';
import 'package:sinicerita/providers/auth_provider.dart';
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

/// Creates a Dio instance that returns active sessions on GET (fetchSessions)
/// and throws a DioException on PATCH (completeSession).
Dio _createDioWithSessionsAndFailingPatch({
  required List<SessionModel> activeSessions,
  required DioException patchException,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Handle GET /api/sessions (fetchSessions)
        if (options.method == 'GET' && options.path.contains('/api/sessions')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Sessions retrieved',
                'data': activeSessions
                    .map((s) => {
                          'id': s.id,
                          'userId': s.userId,
                          'personaId': s.personaId,
                          'status': s.status,
                          'scoreDelta': s.scoreDelta,
                          'analysisSummary': s.analysisSummary,
                          'createdAt': s.createdAt.toIso8601String(),
                          'startedAt': s.startedAt?.toIso8601String(),
                          'completedAt': s.completedAt?.toIso8601String(),
                        })
                    .toList(),
                'meta': {
                  'total': activeSessions.length,
                  'page': 1,
                  'limit': 10,
                  'totalPages': 1,
                },
              },
            ),
          );
          return;
        }

        // Handle PATCH /api/sessions/:id/complete → throw error
        if (options.method == 'PATCH' &&
            options.path.contains('/complete')) {
          handler.reject(
            DioException(
              type: patchException.type,
              requestOptions: options,
              response: patchException.response != null
                  ? Response(
                      requestOptions: options,
                      statusCode: patchException.response!.statusCode,
                      data: patchException.response!.data,
                    )
                  : null,
              message: patchException.message,
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

/// Creates an AuthProvider with a pre-set currentUser (via login mock).
Future<AuthProvider> _createAuthProviderWithPoints(int initialPoints) async {
  final mockStorage = MockSecureStorage();
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Mock login to set currentUser
        if (options.method == 'POST' && options.path.contains('/login')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Login berhasil',
                'data': {
                  'accessToken': 'mock-access-token',
                  'refreshToken': 'mock-refresh-token',
                  'user': {
                    'id': 'user-test-id',
                    'name': 'Test User',
                    'email': 'test@example.com',
                    'role': 'user',
                    'points': initialPoints,
                    'avatarUrl': null,
                    'createdAt': '2024-01-01T00:00:00.000Z',
                  },
                },
              },
            ),
          );
          return;
        }
        handler.reject(
          DioException(
            type: DioExceptionType.unknown,
            requestOptions: options,
          ),
        );
      },
    ),
  );

  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  final authProvider = AuthProvider(apiClient: mockApiClient);
  await authProvider.login('test@example.com', 'password123');
  return authProvider;
}

// ─── Test Main ────────────────────────────────────────────────────────────────

void main() {
  // ─── Property 5: Error Preservation Invariant ───────────────────────────────

  /// **Feature: tahap-7-session-completion, Property 5: Error Preservation Invariant**
  ///
  /// **Validates: Requirements 4.4**
  ///
  /// For any failed session completion (network error or non-2xx status),
  /// the session SHALL remain in the active sessions list unchanged,
  /// AuthProvider.currentUser.points SHALL remain at its previous value,
  /// and errorMessage SHALL be non-null.
  group('Property 5: Error Preservation Invariant', () {
    const int iterations = 120;
    final random = Random(42);

    // ─── Generators ─────────────────────────────────────────────────────────

    /// Generate a random UUID-like string.
    String generateRandomId(Random rng) {
      const chars = 'abcdef0123456789';
      return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    }

    /// Generate a random active SessionModel.
    SessionModel generateRandomActiveSession(Random rng) {
      final now = DateTime(
        2023 + rng.nextInt(3),
        1 + rng.nextInt(12),
        1 + rng.nextInt(28),
        rng.nextInt(24),
        rng.nextInt(60),
      );
      return SessionModel(
        id: generateRandomId(rng),
        userId: generateRandomId(rng),
        personaId: generateRandomId(rng),
        status: 'active',
        createdAt: now,
        startedAt: now.add(Duration(minutes: rng.nextInt(1000))),
      );
    }

    /// Generate a random list of active sessions (1-10 items).
    List<SessionModel> generateRandomSessionList(Random rng) {
      final length = 1 + rng.nextInt(10);
      return List.generate(length, (_) => generateRandomActiveSession(rng));
    }

    /// Generate a random DioException representing various error types.
    DioException generateRandomDioException(Random rng) {
      final types = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.badResponse,
        DioExceptionType.unknown,
        DioExceptionType.sendTimeout,
      ];
      final type = types[rng.nextInt(types.length)];
      final requestOptions =
          RequestOptions(path: '/api/sessions/test-id/complete');

      if (type == DioExceptionType.badResponse) {
        final statusCodes = [409, 403, 500, 400, 401, 502, 503];
        final statusCode = statusCodes[rng.nextInt(statusCodes.length)];
        final messages = [
          'Sesi sudah selesai',
          'Akses ditolak: sesi bukan milik Anda',
          'Internal server error',
          'Terjadi kesalahan pada server.',
          'Bad request',
        ];
        final message = messages[rng.nextInt(messages.length)];

        return DioException(
          type: type,
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: {'success': false, 'message': message},
          ),
        );
      }

      return DioException(
        type: type,
        requestOptions: requestOptions,
        message: 'Simulated ${type.name} error',
      );
    }

    /// Generate a random initial points value (0-100).
    int generateRandomPoints(Random rng) => rng.nextInt(101);

    // ─── Tests ──────────────────────────────────────────────────────────────

    test(
      'For any failed completion, session remains in active list unchanged, '
      'AuthProvider points unchanged, and errorMessage is non-null '
      '($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          // Generate random test data
          final activeSessions = generateRandomSessionList(random);
          final targetIndex = random.nextInt(activeSessions.length);
          final targetSession = activeSessions[targetIndex];
          final initialPoints = generateRandomPoints(random);
          final dioException = generateRandomDioException(random);

          // Create AuthProvider with initial points
          final authProvider =
              await _createAuthProviderWithPoints(initialPoints);

          // Create SessionProvider with mock that fails on PATCH
          final dio = _createDioWithSessionsAndFailingPatch(
            activeSessions: activeSessions,
            patchException: dioException,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          // Populate active sessions via fetchSessions
          await sessionProvider.fetchSessions(status: 'active');

          // Record initial state
          final initialActiveSessions =
              List<SessionModel>.from(sessionProvider.activeSessions);
          final initialActiveCount = initialActiveSessions.length;

          // Verify initial state is correct
          expect(
            initialActiveCount,
            equals(activeSessions.length),
            reason: 'Iteration $i: initial active sessions count should match',
          );
          expect(
            authProvider.currentUser!.points,
            equals(initialPoints),
            reason: 'Iteration $i: initial points should be $initialPoints',
          );

          // Call completeSession — should fail
          final result = await sessionProvider.completeSession(
            targetSession.id,
            authProvider,
          );

          // Property: completeSession returns null on failure
          expect(
            result,
            isNull,
            reason: 'Iteration $i (${dioException.type.name}): '
                'completeSession should return null on failure',
          );

          // Property: session remains in active list unchanged
          expect(
            sessionProvider.activeSessions.length,
            equals(initialActiveCount),
            reason: 'Iteration $i (${dioException.type.name}): '
                'active sessions count should remain $initialActiveCount, '
                'got ${sessionProvider.activeSessions.length}',
          );

          // Property: the target session is still in the active list
          final sessionStillPresent = sessionProvider.activeSessions
              .any((s) => s.id == targetSession.id);
          expect(
            sessionStillPresent,
            isTrue,
            reason: 'Iteration $i (${dioException.type.name}): '
                'target session ${targetSession.id} should still be in '
                'active sessions list after failed completion',
          );

          // Property: the target session is unchanged (same fields)
          final sessionAfterFailure = sessionProvider.activeSessions
              .firstWhere((s) => s.id == targetSession.id);
          expect(
            sessionAfterFailure.status,
            equals('active'),
            reason: 'Iteration $i (${dioException.type.name}): '
                'session status should remain "active"',
          );
          expect(
            sessionAfterFailure.personaId,
            equals(targetSession.personaId),
            reason: 'Iteration $i (${dioException.type.name}): '
                'session personaId should remain unchanged',
          );
          expect(
            sessionAfterFailure.scoreDelta,
            isNull,
            reason: 'Iteration $i (${dioException.type.name}): '
                'session scoreDelta should remain null (not completed)',
          );

          // Property: AuthProvider points unchanged
          expect(
            authProvider.currentUser!.points,
            equals(initialPoints),
            reason: 'Iteration $i (${dioException.type.name}): '
                'AuthProvider points should remain $initialPoints, '
                'got ${authProvider.currentUser!.points}',
          );

          // Property: errorMessage is non-null
          expect(
            sessionProvider.errorMessage,
            isNotNull,
            reason: 'Iteration $i (${dioException.type.name}): '
                'errorMessage should be non-null after failed completion',
          );

          // Property: errorMessage is non-empty
          expect(
            sessionProvider.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'Iteration $i (${dioException.type.name}): '
                'errorMessage should be non-empty after failed completion',
          );
        }
      },
    );

    test(
      'All DioExceptionTypes preserve session state and set errorMessage '
      '(explicit type coverage)',
      () async {
        final allExceptionTypes = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.connectionError,
          DioExceptionType.unknown,
        ];

        final badResponseStatusCodes = [409, 403, 500, 400, 502];
        final badResponseMessages = [
          'Sesi sudah selesai',
          'Akses ditolak: sesi bukan milik Anda',
          'Terjadi kesalahan pada server.',
          'Bad request',
          'Bad gateway',
        ];

        // Test non-badResponse types
        for (final type in allExceptionTypes) {
          final session = SessionModel(
            id: 'session-${type.name}',
            userId: 'user-1',
            personaId: 'persona-1',
            status: 'active',
            createdAt: DateTime(2024, 1, 1),
            startedAt: DateTime(2024, 1, 1, 10, 0),
          );

          final dioException = DioException(
            type: type,
            requestOptions: RequestOptions(path: '/api/sessions/test/complete'),
            message: 'Simulated ${type.name}',
          );

          final authProvider = await _createAuthProviderWithPoints(75);
          final dio = _createDioWithSessionsAndFailingPatch(
            activeSessions: [session],
            patchException: dioException,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          await sessionProvider.fetchSessions(status: 'active');
          final result =
              await sessionProvider.completeSession(session.id, authProvider);

          expect(result, isNull, reason: '${type.name}: should return null');
          expect(sessionProvider.activeSessions.length, equals(1),
              reason: '${type.name}: active sessions count should be 1');
          expect(sessionProvider.activeSessions.first.id, equals(session.id),
              reason: '${type.name}: session should remain');
          expect(authProvider.currentUser!.points, equals(75),
              reason: '${type.name}: points should remain 75');
          expect(sessionProvider.errorMessage, isNotNull,
              reason: '${type.name}: errorMessage should be non-null');
          expect(sessionProvider.errorMessage!.isNotEmpty, isTrue,
              reason: '${type.name}: errorMessage should be non-empty');
        }

        // Test badResponse types with various status codes
        for (var i = 0; i < badResponseStatusCodes.length; i++) {
          final statusCode = badResponseStatusCodes[i];
          final message = badResponseMessages[i];

          final session = SessionModel(
            id: 'session-bad-$statusCode',
            userId: 'user-1',
            personaId: 'persona-1',
            status: 'active',
            createdAt: DateTime(2024, 1, 1),
            startedAt: DateTime(2024, 1, 1, 10, 0),
          );

          final dioException = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: '/api/sessions/test/complete'),
            response: Response(
              requestOptions:
                  RequestOptions(path: '/api/sessions/test/complete'),
              statusCode: statusCode,
              data: {'success': false, 'message': message},
            ),
          );

          final initialPoints = 50 + i * 10;
          final authProvider =
              await _createAuthProviderWithPoints(initialPoints);
          final dio = _createDioWithSessionsAndFailingPatch(
            activeSessions: [session],
            patchException: dioException,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          await sessionProvider.fetchSessions(status: 'active');
          final result =
              await sessionProvider.completeSession(session.id, authProvider);

          expect(result, isNull,
              reason: 'badResponse $statusCode: should return null');
          expect(sessionProvider.activeSessions.length, equals(1),
              reason:
                  'badResponse $statusCode: active sessions count should be 1');
          expect(
              sessionProvider.activeSessions.first.id, equals(session.id),
              reason: 'badResponse $statusCode: session should remain');
          expect(authProvider.currentUser!.points, equals(initialPoints),
              reason:
                  'badResponse $statusCode: points should remain $initialPoints');
          expect(sessionProvider.errorMessage, isNotNull,
              reason:
                  'badResponse $statusCode: errorMessage should be non-null');
          expect(sessionProvider.errorMessage, equals(message),
              reason:
                  'badResponse $statusCode: errorMessage should be "$message"');
        }
      },
    );

    test(
      'Multiple sessions: only target session is relevant, all sessions '
      'preserved after failure ($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          // Generate 2-8 active sessions
          final sessionCount = 2 + random.nextInt(7);
          final activeSessions = List.generate(
            sessionCount,
            (_) => generateRandomActiveSession(random),
          );
          final targetIndex = random.nextInt(activeSessions.length);
          final targetSession = activeSessions[targetIndex];
          final initialPoints = generateRandomPoints(random);
          final dioException = generateRandomDioException(random);

          final authProvider =
              await _createAuthProviderWithPoints(initialPoints);
          final dio = _createDioWithSessionsAndFailingPatch(
            activeSessions: activeSessions,
            patchException: dioException,
          );
          final mockStorage = MockSecureStorage();
          final mockApiClient =
              MockApiClient(mockStorage: mockStorage, dio: dio);
          final sessionProvider = SessionProvider(apiClient: mockApiClient);

          await sessionProvider.fetchSessions(status: 'active');

          // Record all session IDs before
          final sessionIdsBefore =
              sessionProvider.activeSessions.map((s) => s.id).toSet();

          final result = await sessionProvider.completeSession(
            targetSession.id,
            authProvider,
          );

          // Record all session IDs after
          final sessionIdsAfter =
              sessionProvider.activeSessions.map((s) => s.id).toSet();

          // Property: result is null (failure)
          expect(result, isNull,
              reason: 'Iteration $i: should return null on failure');

          // Property: ALL sessions are preserved (same set of IDs)
          expect(
            sessionIdsAfter,
            equals(sessionIdsBefore),
            reason: 'Iteration $i (${dioException.type.name}): '
                'all session IDs should be preserved after failed completion. '
                'Before: $sessionIdsBefore, After: $sessionIdsAfter',
          );

          // Property: session count unchanged
          expect(
            sessionProvider.activeSessions.length,
            equals(sessionCount),
            reason: 'Iteration $i: session count should remain $sessionCount',
          );

          // Property: points unchanged
          expect(
            authProvider.currentUser!.points,
            equals(initialPoints),
            reason: 'Iteration $i: points should remain $initialPoints',
          );

          // Property: errorMessage non-null
          expect(
            sessionProvider.errorMessage,
            isNotNull,
            reason: 'Iteration $i: errorMessage should be non-null',
          );
        }
      },
    );
  });
}
