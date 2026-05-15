import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/providers/auth_provider.dart';

/// Manual mock for SecureStorage that stores data in-memory.
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<bool> isFirstLaunchCompleted() async {
    return _store['first_launch_completed'] == 'true';
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    _store['first_launch_completed'] = 'true';
  }

  @override
  Future<String?> getAccessToken() async {
    return _store['access_token'];
  }

  @override
  Future<String?> getRefreshToken() async {
    return _store['refresh_token'];
  }

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

  void setAccessToken(String token) {
    _store['access_token'] = token;
  }
}

/// Manual mock for ApiClient that uses MockSecureStorage and a real Dio instance.
class MockApiClient implements ApiClient {
  final MockSecureStorage _mockStorage;
  final Dio _dio;

  MockApiClient({required MockSecureStorage mockStorage, Dio? dio})
      : _mockStorage = mockStorage,
        _dio = dio ?? Dio();

  @override
  SecureStorage get storage => _mockStorage;

  @override
  Dio get dio => _dio;
}

void main() {
  group('AuthProvider - first-launch logic', () {
    late MockSecureStorage mockStorage;
    late MockApiClient mockApiClient;
    late AuthProvider authProvider;

    setUp(() {
      mockStorage = MockSecureStorage();
      mockApiClient = MockApiClient(mockStorage: mockStorage);
      authProvider = AuthProvider(apiClient: mockApiClient);
    });

    test('firstLaunchCompleted defaults to false', () {
      expect(authProvider.firstLaunchCompleted, false);
    });

    group('completeFirstLaunch()', () {
      test('sets firstLaunchCompleted to true', () async {
        await authProvider.completeFirstLaunch();

        expect(authProvider.firstLaunchCompleted, true);
      });

      test('calls notifyListeners', () async {
        var listenerCallCount = 0;
        authProvider.addListener(() {
          listenerCallCount++;
        });

        await authProvider.completeFirstLaunch();

        expect(listenerCallCount, 1);
      });

      test('writes flag to storage', () async {
        await authProvider.completeFirstLaunch();

        final flagInStorage = await mockStorage.isFirstLaunchCompleted();
        expect(flagInStorage, true);
      });
    });

    group('checkAuthStatus()', () {
      test('reads first-launch flag from storage (flag not set)', () async {
        // No access token → will be unauthenticated
        await authProvider.checkAuthStatus();

        expect(authProvider.firstLaunchCompleted, false);
      });

      test('reads first-launch flag from storage (flag is true)', () async {
        // Set the flag in storage before calling checkAuthStatus
        await mockStorage.setFirstLaunchCompleted();

        await authProvider.checkAuthStatus();

        expect(authProvider.firstLaunchCompleted, true);
      });

      test(
          'sets firstLaunchCompleted to false when storage returns false (error fallback)',
          () async {
        // SecureStorage.isFirstLaunchCompleted() already catches exceptions
        // and returns false. AuthProvider receives false and sets field accordingly.
        // Here we verify that when no flag is set, the field stays false.
        await authProvider.checkAuthStatus();

        expect(authProvider.firstLaunchCompleted, false);
        expect(authProvider.status, AuthStatus.unauthenticated);
      });
    });
  });
}
