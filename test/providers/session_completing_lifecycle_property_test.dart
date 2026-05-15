// Feature: tahap-7-session-completion, Property 2: isCompleting Lifecycle Invariant
//
// **Validates: Requirements 2.8, 2.9**
//
// For any call to completeSession() (success or failure), verify isCompleting
// is true during execution and false after completion.

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

/// Creates a Dio instance that returns a successful completion response.
Dio _createSuccessDio({
  required int scoreDelta,
  required int newPoints,
  required String summary,
}) {
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
              'message': 'Sesi berhasil diselesaikan',
              'data': {
                'session': {'id': 'test', 'status': 'completed'},
                'scoreDelta': scoreDelta,
                'newPoints': newPoints,
                'summary': summary,
              },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

/// Creates a Dio instance that throws a DioException.
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

/// Creates a SessionProvider with a given Dio and pre-populates an active session.
SessionProvider _createProvider(Dio dio, {String sessionId = 'test-session'}) {
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return SessionProvider(apiClient: mockApiClient);
}

/// Creates an AuthProvider with a mock user for testing.
AuthProvider _createAuthProvider({int initialPoints = 50}) {
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(
    mockStorage: mockStorage,
    dio: Dio(BaseOptions(baseUrl: 'http://localhost:5000')),
  );
  final authProvider = AuthProvider(apiClient: mockApiClient);

  // We need to set currentUser. Use login-like approach via internal state.
  // Since AuthProvider doesn't expose a setter, we'll use a helper approach:
  // Call updatePoints won't work without a user, so we need to simulate login.
  // Instead, we'll create a custom AuthProvider subclass for testing.
  return authProvider;
}

/// A testable AuthProvider that allows setting currentUser directly.
class TestableAuthProvider extends AuthProvider {
  TestableAuthProvider({required super.apiClient});

  void setCurrentUser(UserModel user) {
    // Access the private field via a workaround: call updatePoints won't work
    // without a user. We need to use a different approach.
    // Since AuthProvider uses _currentUser internally, we'll simulate a login.
    // Actually, let's just override the getter.
    _testUser = user;
  }

  UserModel? _testUser;

  @override
  UserModel? get currentUser => _testUser ?? super.currentUser;

  @override
  void updatePoints(int newPoints) {
    if (_testUser == null) return;
    _testUser = UserModel(
      id: _testUser!.id,
      name: _testUser!.name,
      email: _testUser!.email,
      role: _testUser!.role,
      points: newPoints,
      avatarUrl: _testUser!.avatarUrl,
      createdAt: _testUser!.createdAt,
    );
    notifyListeners();
  }
}

/// Creates a TestableAuthProvider with a mock user.
TestableAuthProvider _createTestableAuthProvider({int initialPoints = 50}) {
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(
    mockStorage: mockStorage,
    dio: Dio(BaseOptions(baseUrl: 'http://localhost:5000')),
  );
  final authProvider = TestableAuthProvider(apiClient: mockApiClient);
  authProvider.setCurrentUser(
    UserModel(
      id: 'user-1',
      name: 'Test User',
      email: 'test@example.com',
      role: 'user',
      points: initialPoints,
      createdAt: DateTime(2024, 1, 1),
    ),
  );
  return authProvider;
}

// ─── Property Test ────────────────────────────────────────────────────────────

void main() {
  group('Property 2: isCompleting Lifecycle Invariant', () {
    const int iterations = 100;
    final random = Random(42);

    /// DioExceptionTypes to randomly pick from for failure scenarios.
    const dioExceptionTypes = [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badResponse,
      DioExceptionType.unknown,
    ];

    /// Status codes for badResponse scenarios.
    const badResponseStatusCodes = [400, 401, 403, 404, 409, 500, 502, 503];

    /// Error messages for badResponse scenarios.
    const errorMessages = [
      'Sesi sudah selesai',
      'Akses ditolak: sesi bukan milik Anda',
      'Internal server error',
      'Too many requests, please try again later',
    ];

    /// Generate a random session ID.
    String generateSessionId(Random rng) {
      const chars = 'abcdef0123456789';
      return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    }

    /// Generate a random scoreDelta in [-20, +20].
    int generateScoreDelta(Random rng) => rng.nextInt(41) - 20;

    /// Generate a random newPoints in [0, 100].
    int generateNewPoints(Random rng) => rng.nextInt(101);

    /// Generate a random summary string.
    String generateSummary(Random rng) {
      const summaries = [
        'Berdasarkan percakapan Anda, terlihat peningkatan mood.',
        'Sesi ini menunjukkan penurunan emosional yang perlu diperhatikan.',
        'Percakapan berjalan netral tanpa perubahan signifikan.',
        'Anda menunjukkan keterbukaan yang baik dalam sesi ini.',
        'Ada tanda-tanda stres yang perlu ditangani lebih lanjut.',
      ];
      return summaries[rng.nextInt(summaries.length)];
    }

    /// Generate a random DioException for failure scenarios.
    DioException generateDioException(Random rng) {
      final type = dioExceptionTypes[rng.nextInt(dioExceptionTypes.length)];
      final requestOptions = RequestOptions(
        path: '/api/sessions/test-session/complete',
      );

      if (type == DioExceptionType.badResponse) {
        final statusCode =
            badResponseStatusCodes[rng.nextInt(badResponseStatusCodes.length)];
        final message = errorMessages[rng.nextInt(errorMessages.length)];
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

    test(
      'isCompleting transitions to true during execution and false after '
      'for random success/failure outcomes ($iterations iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final isSuccessScenario = random.nextBool();
          final sessionId = generateSessionId(random);

          late SessionProvider provider;
          final authProvider = _createTestableAuthProvider(
            initialPoints: generateNewPoints(random),
          );

          if (isSuccessScenario) {
            // Success scenario
            final scoreDelta = generateScoreDelta(random);
            final newPoints = generateNewPoints(random);
            final summary = generateSummary(random);

            final dio = _createSuccessDio(
              scoreDelta: scoreDelta,
              newPoints: newPoints,
              summary: summary,
            );
            provider = _createProvider(dio, sessionId: sessionId);
          } else {
            // Failure scenario
            final exception = generateDioException(random);
            final dio = _createFailingDio(exception);
            provider = _createProvider(dio, sessionId: sessionId);
          }

          // 1. Before calling completeSession: isCompleting == false
          expect(
            provider.isCompleting,
            isFalse,
            reason: 'Iteration $i (${isSuccessScenario ? "success" : "failure"}): '
                'isCompleting should be false before calling completeSession',
          );

          // 2. During execution: capture isCompleting transitions via listener
          final isCompletingValues = <bool>[];
          void listener() {
            isCompletingValues.add(provider.isCompleting);
          }

          provider.addListener(listener);

          // Call completeSession
          await provider.completeSession(sessionId, authProvider);

          provider.removeListener(listener);

          // 3. After completeSession returns: isCompleting == false
          expect(
            provider.isCompleting,
            isFalse,
            reason: 'Iteration $i (${isSuccessScenario ? "success" : "failure"}): '
                'isCompleting should be false after completeSession returns',
          );

          // 4. Verify that isCompleting was true at some point during execution
          expect(
            isCompletingValues.contains(true),
            isTrue,
            reason: 'Iteration $i (${isSuccessScenario ? "success" : "failure"}): '
                'isCompleting should have been true during execution. '
                'Captured values: $isCompletingValues',
          );

          // 5. Verify the final captured value is false (last notifyListeners set it to false)
          expect(
            isCompletingValues.last,
            isFalse,
            reason: 'Iteration $i (${isSuccessScenario ? "success" : "failure"}): '
                'The last notifyListeners() call should have isCompleting == false. '
                'Captured values: $isCompletingValues',
          );
        }
      },
    );

    test(
      'isCompleting lifecycle holds for all DioExceptionType values explicitly',
      () async {
        for (final type in dioExceptionTypes) {
          final requestOptions = RequestOptions(
            path: '/api/sessions/test-session/complete',
          );

          final DioException exception;
          if (type == DioExceptionType.badResponse) {
            exception = DioException(
              type: type,
              requestOptions: requestOptions,
              response: Response(
                requestOptions: requestOptions,
                statusCode: 409,
                data: {'success': false, 'message': 'Sesi sudah selesai'},
              ),
            );
          } else {
            exception = DioException(
              type: type,
              requestOptions: requestOptions,
              message: 'Simulated ${type.name} error',
            );
          }

          final dio = _createFailingDio(exception);
          final provider = _createProvider(dio);
          final authProvider = _createTestableAuthProvider();

          // Before
          expect(provider.isCompleting, isFalse,
              reason: '${type.name}: isCompleting should be false before call');

          // During — capture via listener
          final isCompletingValues = <bool>[];
          void listener() {
            isCompletingValues.add(provider.isCompleting);
          }

          provider.addListener(listener);
          await provider.completeSession('test-session', authProvider);
          provider.removeListener(listener);

          // After
          expect(provider.isCompleting, isFalse,
              reason: '${type.name}: isCompleting should be false after call');

          // Was true during
          expect(isCompletingValues.contains(true), isTrue,
              reason: '${type.name}: isCompleting should have been true during execution');

          // Ends false
          expect(isCompletingValues.last, isFalse,
              reason: '${type.name}: last captured isCompleting should be false');
        }
      },
    );

    test(
      'isCompleting lifecycle holds for success scenarios with various '
      'scoreDelta and newPoints values ($iterations iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final scoreDelta = generateScoreDelta(random);
          final newPoints = generateNewPoints(random);
          final summary = generateSummary(random);
          final sessionId = generateSessionId(random);

          final dio = _createSuccessDio(
            scoreDelta: scoreDelta,
            newPoints: newPoints,
            summary: summary,
          );
          final provider = _createProvider(dio, sessionId: sessionId);
          final authProvider = _createTestableAuthProvider(
            initialPoints: random.nextInt(101),
          );

          // Before
          expect(provider.isCompleting, isFalse,
              reason: 'Iteration $i: isCompleting should be false before call');

          // During — capture via listener
          final isCompletingValues = <bool>[];
          void listener() {
            isCompletingValues.add(provider.isCompleting);
          }

          provider.addListener(listener);
          final result = await provider.completeSession(sessionId, authProvider);
          provider.removeListener(listener);

          // After
          expect(provider.isCompleting, isFalse,
              reason: 'Iteration $i: isCompleting should be false after call');

          // Was true during
          expect(isCompletingValues.contains(true), isTrue,
              reason: 'Iteration $i: isCompleting should have been true during execution');

          // Ends false
          expect(isCompletingValues.last, isFalse,
              reason: 'Iteration $i: last captured isCompleting should be false');

          // Verify success result is returned
          expect(result, isNotNull,
              reason: 'Iteration $i: result should not be null for success scenario');
        }
      },
    );
  });
}
