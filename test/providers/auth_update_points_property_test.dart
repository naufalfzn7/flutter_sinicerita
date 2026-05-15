// Feature: tahap-7-session-completion, Property 4: Global Points Update on Success

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/providers/auth_provider.dart';

/// In-memory mock for SecureStorage.
class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<bool> isFirstLaunchCompleted() async =>
      _store['first_launch_completed'] == 'true';

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

/// Mock ApiClient that uses in-memory storage and a plain Dio instance.
class _MockApiClient implements ApiClient {
  final _MockSecureStorage _mockStorage;
  final Dio _dio;

  _MockApiClient({required _MockSecureStorage mockStorage})
      : _mockStorage = mockStorage,
        _dio = Dio();

  @override
  SecureStorage get storage => _mockStorage;

  @override
  Dio get dio => _dio;
}



void main() {
  // ─── Property 4: Global Points Update on Success ────────────────────────────

  /// **Feature: tahap-7-session-completion, Property 4: Global Points Update on Success**
  ///
  /// **Validates: Requirements 4.1, 4.2**
  ///
  /// For any newPoints (0–100), verify authProvider.currentUser.points == newPoints
  /// after calling updatePoints. Also verify notifyListeners was called.
  group('Property 4: Global Points Update on Success', () {
    late _MockSecureStorage mockStorage;
    late _MockApiClient mockApiClient;
    late AuthProvider authProvider;

    /// Creates an AuthProvider with a currentUser already set.
    /// Uses a DioAdapter to mock the login endpoint.
    AuthProvider createAuthProviderWithInitialPoints(int initialPoints) {
      mockStorage = _MockSecureStorage();

      // Create a Dio with a mock interceptor that responds to login
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/api/auth/login')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Login berhasil',
                    'data': {
                      'accessToken': 'fake-access-token',
                      'refreshToken': 'fake-refresh-token',
                      'user': {
                        'id': 'test-user-id',
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
            } else {
              handler.next(options);
            }
          },
        ),
      );

      // Create a mock ApiClient with the custom Dio
      final apiClient = _MockApiClientWithDio(
        mockStorage: mockStorage,
        dio: dio,
      );
      return AuthProvider(apiClient: apiClient);
    }

    Glados(any.intInRange(0, 101)).test(
      'updatePoints(newPoints) sets currentUser.points == newPoints (glados)',
      (newPoints) async {
        // Setup: create provider with a user that has different initial points
        final initialPoints = (newPoints + 50) % 101; // Different from newPoints
        authProvider = createAuthProviderWithInitialPoints(initialPoints);

        // Login to set _currentUser
        await authProvider.login('test@example.com', 'password');
        expect(authProvider.currentUser, isNotNull,
            reason: 'currentUser should be set after login');
        expect(authProvider.currentUser!.points, equals(initialPoints));

        // Act: call updatePoints
        authProvider.updatePoints(newPoints);

        // Assert: points updated to exactly newPoints
        expect(
          authProvider.currentUser!.points,
          equals(newPoints),
          reason: 'After updatePoints($newPoints), '
              'currentUser.points should be $newPoints, '
              'got ${authProvider.currentUser!.points}',
        );
      },
    );

    test(
      'updatePoints sets currentUser.points == newPoints for 200 random iterations',
      () async {
        const int iterations = 200;
        final random = Random(42);

        for (var i = 0; i < iterations; i++) {
          final newPoints = random.nextInt(101); // 0 to 100
          final initialPoints = random.nextInt(101); // Random initial

          authProvider = createAuthProviderWithInitialPoints(initialPoints);
          await authProvider.login('test@example.com', 'password');

          // Track listener calls
          var listenerCallCount = 0;
          authProvider.addListener(() {
            listenerCallCount++;
          });

          // Act
          authProvider.updatePoints(newPoints);

          // Assert: points updated
          expect(
            authProvider.currentUser!.points,
            equals(newPoints),
            reason: 'Iteration $i: After updatePoints($newPoints), '
                'currentUser.points should be $newPoints, '
                'got ${authProvider.currentUser!.points}',
          );

          // Assert: notifyListeners was called
          expect(
            listenerCallCount,
            equals(1),
            reason: 'Iteration $i: notifyListeners should be called exactly '
                'once after updatePoints, got $listenerCallCount calls',
          );

          // Assert: other user fields remain unchanged
          expect(authProvider.currentUser!.id, equals('test-user-id'));
          expect(authProvider.currentUser!.name, equals('Test User'));
          expect(authProvider.currentUser!.email, equals('test@example.com'));
          expect(authProvider.currentUser!.role, equals('user'));
        }
      },
    );

    test(
      'updatePoints is a no-op when currentUser is null (edge case)',
      () {
        // Create provider without logging in (currentUser is null)
        mockStorage = _MockSecureStorage();
        mockApiClient = _MockApiClient(mockStorage: mockStorage);
        authProvider = AuthProvider(apiClient: mockApiClient);

        expect(authProvider.currentUser, isNull);

        var listenerCallCount = 0;
        authProvider.addListener(() {
          listenerCallCount++;
        });

        // Act: should not crash
        authProvider.updatePoints(50);

        // Assert: still null, no crash, no notifyListeners
        expect(authProvider.currentUser, isNull);
        expect(listenerCallCount, equals(0),
            reason: 'notifyListeners should NOT be called when currentUser is null');
      },
    );

    Glados(any.intInRange(0, 101)).test(
      'updatePoints preserves all user fields except points (glados)',
      (newPoints) async {
        final initialPoints = (newPoints + 30) % 101;
        authProvider = createAuthProviderWithInitialPoints(initialPoints);
        await authProvider.login('test@example.com', 'password');

        final userBefore = authProvider.currentUser!;

        // Act
        authProvider.updatePoints(newPoints);

        final userAfter = authProvider.currentUser!;

        // Assert: only points changed
        expect(userAfter.id, equals(userBefore.id));
        expect(userAfter.name, equals(userBefore.name));
        expect(userAfter.email, equals(userBefore.email));
        expect(userAfter.role, equals(userBefore.role));
        expect(userAfter.avatarUrl, equals(userBefore.avatarUrl));
        expect(userAfter.createdAt, equals(userBefore.createdAt));
        expect(userAfter.points, equals(newPoints));
      },
    );
  });
}

/// Mock ApiClient that accepts a custom Dio instance.
class _MockApiClientWithDio implements ApiClient {
  final _MockSecureStorage _mockStorage;
  final Dio _dio;

  _MockApiClientWithDio({
    required _MockSecureStorage mockStorage,
    required Dio dio,
  })  : _mockStorage = mockStorage,
        _dio = dio;

  @override
  SecureStorage get storage => _mockStorage;

  @override
  Dio get dio => _dio;
}
