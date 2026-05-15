// Feature: tahap-7-session-completion, Property 3: Session State Transition on Success
//
// **Validates: Requirements 2.4, 4.3**
//
// For any active session successfully completed, verify session removed from
// active list and added to beginning of completed list with correct status,
// scoreDelta, and analysisSummary.

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
  Future<String?> getAccessToken() async => _store['access_token'] ?? 'mock-token';

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

/// Manual mock for ApiClient that accepts a custom Dio instance.
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

// ─── Test Helpers ─────────────────────────────────────────────────────────────

/// Creates a Dio instance that:
/// - Returns a session list for GET /api/sessions (to populate active sessions)
/// - Returns a successful completion response for PATCH /api/sessions/:id/complete
Dio _createMockDio({
  required List<SessionModel> activeSessions,
  required int scoreDelta,
  required int newPoints,
  required String summary,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Handle GET /api/sessions?status=active
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

        // Handle PATCH /api/sessions/:id/complete
        if (options.method == 'PATCH' && options.path.contains('/complete')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Sesi berhasil diselesaikan',
                'data': {
                  'scoreDelta': scoreDelta,
                  'newPoints': newPoints,
                  'summary': summary,
                },
              },
            ),
          );
          return;
        }

        // Default: resolve with empty success
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'message': 'OK', 'data': null},
          ),
        );
      },
    ),
  );
  return dio;
}

/// Creates a SessionProvider with mocked Dio pre-configured for completion tests.
SessionProvider _createProvider(Dio dio) {
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return SessionProvider(apiClient: mockApiClient);
}

/// Creates an AuthProvider with a mock user that has the given initial points.
AuthProvider _createAuthProvider({required int initialPoints}) {
  final mockStorage = MockSecureStorage();
  // Create a Dio that returns a user for login
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
              'message': 'Login successful',
              'data': {
                'accessToken': 'mock-access-token',
                'refreshToken': 'mock-refresh-token',
                'user': {
                  'id': 'user-001',
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
      },
    ),
  );
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return AuthProvider(apiClient: mockApiClient);
}

// ─── Property Tests ───────────────────────────────────────────────────────────

void main() {
  group('Property 3: Session State Transition on Success', () {
    /// **Feature: tahap-7-session-completion, Property 3: Session State Transition on Success**
    ///
    /// **Validates: Requirements 2.4, 4.3**
    ///
    /// For any active session successfully completed, verify:
    /// 1. Session is removed from activeSessions
    /// 2. Session is at index 0 of completedSessions
    /// 3. completedSession.status == 'completed'
    /// 4. completedSession.scoreDelta == the response scoreDelta
    /// 5. completedSession.analysisSummary == the response summary
    test(
      'For any active session successfully completed, session is removed from '
      'active list and added to beginning of completed list with correct '
      'status, scoreDelta, and analysisSummary (100+ random iterations)',
      () async {
        const int iterations = 120;
        final random = Random(42);

        for (var i = 0; i < iterations; i++) {
          // Generate random test data
          final sessionId = 'session-${random.nextInt(999999).toString().padLeft(6, '0')}';
          final personaId = 'persona-${random.nextInt(999999).toString().padLeft(6, '0')}';
          final userId = 'user-${random.nextInt(999999).toString().padLeft(6, '0')}';
          final scoreDelta = random.nextInt(41) - 20; // [-20, +20]
          final newPoints = random.nextInt(101); // [0, 100]

          // Generate random summary string
          const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,';
          final summaryLength = 10 + random.nextInt(200);
          final summary = List.generate(
            summaryLength,
            (_) => chars[random.nextInt(chars.length)],
          ).join();

          // Create the active session
          final activeSession = SessionModel(
            id: sessionId,
            userId: userId,
            personaId: personaId,
            status: 'active',
            createdAt: DateTime(2024, 1, 1).add(Duration(days: random.nextInt(365))),
            startedAt: DateTime(2024, 1, 1).add(Duration(days: random.nextInt(365))),
          );

          // Create mock Dio that returns the session list and completion response
          final dio = _createMockDio(
            activeSessions: [activeSession],
            scoreDelta: scoreDelta,
            newPoints: newPoints,
            summary: summary,
          );

          // Create provider and populate active sessions via fetchSessions
          final provider = _createProvider(dio);
          await provider.fetchSessions(status: 'active');

          // Verify session is in active list before completion
          expect(
            provider.activeSessions.any((s) => s.id == sessionId),
            isTrue,
            reason: 'Iteration $i: session should be in activeSessions before completion',
          );
          expect(
            provider.completedSessions.any((s) => s.id == sessionId),
            isFalse,
            reason: 'Iteration $i: session should NOT be in completedSessions before completion',
          );

          // Create AuthProvider with mock user
          final authProvider = _createAuthProvider(initialPoints: newPoints - scoreDelta);
          await authProvider.login('test@example.com', 'password');

          // Call completeSession
          final result = await provider.completeSession(sessionId, authProvider);

          // Verify result is not null (success)
          expect(
            result,
            isNotNull,
            reason: 'Iteration $i: completeSession should return non-null on success',
          );

          // Property: session is removed from activeSessions
          expect(
            provider.activeSessions.any((s) => s.id == sessionId),
            isFalse,
            reason: 'Iteration $i: session "$sessionId" should be removed from '
                'activeSessions after successful completion',
          );

          // Property: session is at index 0 of completedSessions
          expect(
            provider.completedSessions.isNotEmpty,
            isTrue,
            reason: 'Iteration $i: completedSessions should not be empty after completion',
          );
          expect(
            provider.completedSessions[0].id,
            equals(sessionId),
            reason: 'Iteration $i: completed session should be at index 0 '
                'of completedSessions. Got: ${provider.completedSessions[0].id}',
          );

          // Property: completedSession.status == 'completed'
          expect(
            provider.completedSessions[0].status,
            equals('completed'),
            reason: 'Iteration $i: completedSession.status should be "completed". '
                'Got: "${provider.completedSessions[0].status}"',
          );

          // Property: completedSession.scoreDelta == the response scoreDelta
          expect(
            provider.completedSessions[0].scoreDelta,
            equals(scoreDelta),
            reason: 'Iteration $i: completedSession.scoreDelta should be $scoreDelta. '
                'Got: ${provider.completedSessions[0].scoreDelta}',
          );

          // Property: completedSession.analysisSummary == the response summary
          expect(
            provider.completedSessions[0].analysisSummary,
            equals(summary),
            reason: 'Iteration $i: completedSession.analysisSummary should match '
                'the response summary. Got: "${provider.completedSessions[0].analysisSummary}"',
          );
        }
      },
    );

    test(
      'Completed session is prepended (index 0) even when completedSessions '
      'already has items (100 random iterations)',
      () async {
        const int iterations = 100;
        final random = Random(99);

        for (var i = 0; i < iterations; i++) {
          // Generate random test data
          final sessionId = 'active-session-$i-${random.nextInt(99999)}';
          final personaId = 'persona-$i';
          final scoreDelta = random.nextInt(41) - 20; // [-20, +20]
          final newPoints = random.nextInt(101); // [0, 100]
          final summary = 'Summary for iteration $i - ${random.nextInt(99999)}';

          // Create the active session to be completed
          final activeSession = SessionModel(
            id: sessionId,
            userId: 'user-$i',
            personaId: personaId,
            status: 'active',
            createdAt: DateTime(2024, 1, 1),
            startedAt: DateTime(2024, 1, 1),
          );

          // Create a Dio that handles both fetch and complete
          final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                // Handle GET /api/sessions?status=active
                if (options.method == 'GET' &&
                    options.queryParameters['status'] == 'active') {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'success': true,
                        'message': 'OK',
                        'data': [
                          {
                            'id': activeSession.id,
                            'userId': activeSession.userId,
                            'personaId': activeSession.personaId,
                            'status': 'active',
                            'createdAt': activeSession.createdAt.toIso8601String(),
                            'startedAt': activeSession.startedAt?.toIso8601String(),
                          },
                        ],
                        'meta': {'total': 1, 'page': 1, 'limit': 10, 'totalPages': 1},
                      },
                    ),
                  );
                  return;
                }

                // Handle GET /api/sessions?status=completed (pre-existing completed sessions)
                if (options.method == 'GET' &&
                    options.queryParameters['status'] == 'completed') {
                  final existingCompleted = List.generate(
                    2 + random.nextInt(3),
                    (idx) => {
                      'id': 'existing-completed-$i-$idx',
                      'userId': 'user-$i',
                      'personaId': 'persona-$idx',
                      'status': 'completed',
                      'scoreDelta': random.nextInt(41) - 20,
                      'analysisSummary': 'Existing summary $idx',
                      'createdAt': DateTime(2024, 1, 1).toIso8601String(),
                      'startedAt': DateTime(2024, 1, 1).toIso8601String(),
                      'completedAt': DateTime(2024, 1, 2).toIso8601String(),
                    },
                  );
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'success': true,
                        'message': 'OK',
                        'data': existingCompleted,
                        'meta': {
                          'total': existingCompleted.length,
                          'page': 1,
                          'limit': 10,
                          'totalPages': 1,
                        },
                      },
                    ),
                  );
                  return;
                }

                // Handle PATCH /api/sessions/:id/complete
                if (options.method == 'PATCH' && options.path.contains('/complete')) {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'success': true,
                        'message': 'Sesi berhasil diselesaikan',
                        'data': {
                          'scoreDelta': scoreDelta,
                          'newPoints': newPoints,
                          'summary': summary,
                        },
                      },
                    ),
                  );
                  return;
                }

                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'success': true, 'message': 'OK', 'data': null},
                  ),
                );
              },
            ),
          );

          final provider = _createProvider(dio);

          // Populate completed sessions first
          await provider.fetchSessions(status: 'completed');
          final preExistingCount = provider.completedSessions.length;
          expect(
            preExistingCount,
            greaterThan(0),
            reason: 'Iteration $i: should have pre-existing completed sessions',
          );

          // Populate active sessions
          await provider.fetchSessions(status: 'active');

          // Create AuthProvider
          final authProvider = _createAuthProvider(initialPoints: newPoints - scoreDelta);
          await authProvider.login('test@example.com', 'password');

          // Complete the session
          final result = await provider.completeSession(sessionId, authProvider);

          expect(result, isNotNull,
              reason: 'Iteration $i: completeSession should succeed');

          // Property: new completed session is at index 0 (prepended)
          expect(
            provider.completedSessions[0].id,
            equals(sessionId),
            reason: 'Iteration $i: newly completed session should be at index 0. '
                'Got: "${provider.completedSessions[0].id}"',
          );

          // Property: total completed count increased by 1
          expect(
            provider.completedSessions.length,
            equals(preExistingCount + 1),
            reason: 'Iteration $i: completedSessions.length should increase by 1. '
                'Was $preExistingCount, now ${provider.completedSessions.length}',
          );

          // Property: session preserves original ID
          expect(
            provider.completedSessions[0].id,
            equals(sessionId),
            reason: 'Iteration $i: completed session should preserve original ID',
          );

          // Property: status, scoreDelta, analysisSummary are correct
          expect(provider.completedSessions[0].status, equals('completed'));
          expect(provider.completedSessions[0].scoreDelta, equals(scoreDelta));
          expect(provider.completedSessions[0].analysisSummary, equals(summary));
        }
      },
    );
  });
}
