import 'dart:math';

import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/providers/admin_provider.dart';

// Feature: admin-panel, Property 4: Pagination stops at last page
//
// **Validates: Requirements 4.4, 8.4**
//
// For any pagination state where the current page is greater than or equal to
// `totalPages`, calling `fetchMore` SHALL NOT trigger an additional API request.
// For any state where current page is less than `totalPages`, calling `fetchMore`
// SHALL request page + 1.

/// Manual mock for SecureStorage that stores data in-memory.
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

/// Tracks API calls made through Dio interceptors.
class ApiCallTracker {
  final List<RequestOptions> calls = [];
  int get callCount => calls.length;
  void clear() => calls.clear();
}

/// Creates a Dio that:
/// - On the FIRST call (fetchPersonas/fetchUsers to set state): returns the
///   desired page/totalPages in meta.
/// - On SUBSEQUENT calls (fetchMore): tracks the call and returns next page meta.
Dio _createStatefulDio({
  required int desiredPage,
  required int totalPages,
  required ApiCallTracker tracker,
}) {
  var isFirstCall = true;

  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (isFirstCall) {
          // First call sets the provider's internal state
          isFirstCall = false;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Data retrieved',
                'data': <dynamic>[],
                'meta': {
                  'total': totalPages * 10,
                  'page': desiredPage,
                  'limit': 10,
                  'totalPages': totalPages,
                },
              },
            ),
          );
        } else {
          // Subsequent calls are tracked (these are fetchMore calls)
          tracker.calls.add(options);
          final queryPage = options.queryParameters['page'] as int? ?? 1;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Data retrieved',
                'data': <dynamic>[],
                'meta': {
                  'total': totalPages * 10,
                  'page': queryPage,
                  'limit': 10,
                  'totalPages': totalPages,
                },
              },
            ),
          );
        }
      },
    ),
  );
  return dio;
}

/// Creates an AdminProvider with persona pagination state set to [page]/[totalPages].
/// Returns the provider and a tracker that only counts calls AFTER the initial fetch.
Future<(AdminProvider, ApiCallTracker)> _createPersonaProviderAtPage({
  required int page,
  required int totalPages,
}) async {
  final tracker = ApiCallTracker();
  final dio = _createStatefulDio(
    desiredPage: page,
    totalPages: totalPages,
    tracker: tracker,
  );
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  final provider = AdminProvider(apiClient: mockApiClient);

  // This sets _personaPage = page, _personaTotalPages = totalPages
  await provider.fetchPersonas();

  return (provider, tracker);
}

/// Creates an AdminProvider with user pagination state set to [page]/[totalPages].
Future<(AdminProvider, ApiCallTracker)> _createUserProviderAtPage({
  required int page,
  required int totalPages,
}) async {
  final tracker = ApiCallTracker();
  final dio = _createStatefulDio(
    desiredPage: page,
    totalPages: totalPages,
    tracker: tracker,
  );
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  final provider = AdminProvider(apiClient: mockApiClient);

  // This sets _userPage = page, _userTotalPages = totalPages
  await provider.fetchUsers();

  return (provider, tracker);
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Glados property-based tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 4: Pagination stops at last page (Personas - Glados)', () {
    Glados2(any.intInRange(1, 100), any.intInRange(1, 100)).test(
      'fetchMorePersonas does NOT trigger API call when page >= totalPages',
      (page, totalPagesBase) async {
        // Ensure page >= totalPages
        final totalPages = totalPagesBase;
        final effectivePage = totalPages + (page - 1); // always >= totalPages

        final (provider, tracker) = await _createPersonaProviderAtPage(
          page: effectivePage,
          totalPages: totalPages,
        );

        expect(provider.personaPage, equals(effectivePage));
        expect(provider.personaTotalPages, equals(totalPages));

        await provider.fetchMorePersonas();

        expect(
          tracker.callCount,
          equals(0),
          reason: 'fetchMorePersonas should NOT trigger API call when '
              'page ($effectivePage) >= totalPages ($totalPages)',
        );
      },
    );

    Glados2(any.intInRange(1, 99), any.intInRange(2, 100)).test(
      'fetchMorePersonas DOES trigger API call when page < totalPages',
      (pageBase, totalPages) async {
        // Ensure page < totalPages
        final page = ((pageBase - 1) % (totalPages - 1)) + 1; // 1..totalPages-1

        final (provider, tracker) = await _createPersonaProviderAtPage(
          page: page,
          totalPages: totalPages,
        );

        expect(provider.personaPage, equals(page));
        expect(provider.personaTotalPages, equals(totalPages));

        await provider.fetchMorePersonas();

        expect(
          tracker.callCount,
          equals(1),
          reason: 'fetchMorePersonas SHOULD trigger API call when '
              'page ($page) < totalPages ($totalPages)',
        );

        final requestedPage =
            tracker.calls.first.queryParameters['page'] as int;
        expect(
          requestedPage,
          equals(page + 1),
          reason: 'fetchMorePersonas should request page ${page + 1} '
              'but requested page $requestedPage',
        );
      },
    );
  });

  group('Property 4: Pagination stops at last page (Users - Glados)', () {
    Glados2(any.intInRange(1, 100), any.intInRange(1, 100)).test(
      'fetchMoreUsers does NOT trigger API call when page >= totalPages',
      (page, totalPagesBase) async {
        final totalPages = totalPagesBase;
        final effectivePage = totalPages + (page - 1);

        final (provider, tracker) = await _createUserProviderAtPage(
          page: effectivePage,
          totalPages: totalPages,
        );

        expect(provider.userPage, equals(effectivePage));
        expect(provider.userTotalPages, equals(totalPages));

        await provider.fetchMoreUsers();

        expect(
          tracker.callCount,
          equals(0),
          reason: 'fetchMoreUsers should NOT trigger API call when '
              'page ($effectivePage) >= totalPages ($totalPages)',
        );
      },
    );

    Glados2(any.intInRange(1, 99), any.intInRange(2, 100)).test(
      'fetchMoreUsers DOES trigger API call when page < totalPages',
      (pageBase, totalPages) async {
        final page = ((pageBase - 1) % (totalPages - 1)) + 1;

        final (provider, tracker) = await _createUserProviderAtPage(
          page: page,
          totalPages: totalPages,
        );

        expect(provider.userPage, equals(page));
        expect(provider.userTotalPages, equals(totalPages));

        await provider.fetchMoreUsers();

        expect(
          tracker.callCount,
          equals(1),
          reason: 'fetchMoreUsers SHOULD trigger API call when '
              'page ($page) < totalPages ($totalPages)',
        );

        final requestedPage =
            tracker.calls.first.queryParameters['page'] as int;
        expect(
          requestedPage,
          equals(page + 1),
          reason: 'fetchMoreUsers should request page ${page + 1} '
              'but requested page $requestedPage',
        );
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Iteration-based tests (150+ iterations for comprehensive coverage)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property 4: Pagination boundary (iteration-based, 150 iterations)', () {
    const int iterations = 150;
    final random = Random(42);

    test(
      'fetchMorePersonas: no API call when page >= totalPages',
      () async {
        for (var i = 0; i < iterations; i++) {
          final totalPages = random.nextInt(50) + 1; // 1-50
          final page = totalPages + random.nextInt(10); // >= totalPages

          final (provider, tracker) = await _createPersonaProviderAtPage(
            page: page,
            totalPages: totalPages,
          );

          await provider.fetchMorePersonas();

          expect(
            tracker.callCount,
            equals(0),
            reason: 'Iteration $i: fetchMorePersonas should NOT call API '
                'when page=$page >= totalPages=$totalPages',
          );
        }
      },
    );

    test(
      'fetchMorePersonas: API call triggered and requests page+1 when page < totalPages',
      () async {
        for (var i = 0; i < iterations; i++) {
          final totalPages = random.nextInt(49) + 2; // 2-50
          final page = random.nextInt(totalPages - 1) + 1; // 1..totalPages-1

          final (provider, tracker) = await _createPersonaProviderAtPage(
            page: page,
            totalPages: totalPages,
          );

          await provider.fetchMorePersonas();

          expect(
            tracker.callCount,
            equals(1),
            reason: 'Iteration $i: fetchMorePersonas SHOULD call API '
                'when page=$page < totalPages=$totalPages',
          );

          final requestedPage =
              tracker.calls.first.queryParameters['page'] as int;
          expect(
            requestedPage,
            equals(page + 1),
            reason: 'Iteration $i: should request page=${page + 1}, '
                'got page=$requestedPage',
          );
        }
      },
    );

    test(
      'fetchMoreUsers: no API call when page >= totalPages',
      () async {
        for (var i = 0; i < iterations; i++) {
          final totalPages = random.nextInt(50) + 1; // 1-50
          final page = totalPages + random.nextInt(10); // >= totalPages

          final (provider, tracker) = await _createUserProviderAtPage(
            page: page,
            totalPages: totalPages,
          );

          await provider.fetchMoreUsers();

          expect(
            tracker.callCount,
            equals(0),
            reason: 'Iteration $i: fetchMoreUsers should NOT call API '
                'when page=$page >= totalPages=$totalPages',
          );
        }
      },
    );

    test(
      'fetchMoreUsers: API call triggered and requests page+1 when page < totalPages',
      () async {
        for (var i = 0; i < iterations; i++) {
          final totalPages = random.nextInt(49) + 2; // 2-50
          final page = random.nextInt(totalPages - 1) + 1; // 1..totalPages-1

          final (provider, tracker) = await _createUserProviderAtPage(
            page: page,
            totalPages: totalPages,
          );

          await provider.fetchMoreUsers();

          expect(
            tracker.callCount,
            equals(1),
            reason: 'Iteration $i: fetchMoreUsers SHOULD call API '
                'when page=$page < totalPages=$totalPages',
          );

          final requestedPage =
              tracker.calls.first.queryParameters['page'] as int;
          expect(
            requestedPage,
            equals(page + 1),
            reason: 'Iteration $i: should request page=${page + 1}, '
                'got page=$requestedPage',
          );
        }
      },
    );

    test('boundary: single page (page == totalPages == 1) — no fetch', () async {
      final (personaProvider, personaTracker) =
          await _createPersonaProviderAtPage(page: 1, totalPages: 1);
      await personaProvider.fetchMorePersonas();
      expect(personaTracker.callCount, equals(0));

      final (userProvider, userTracker) =
          await _createUserProviderAtPage(page: 1, totalPages: 1);
      await userProvider.fetchMoreUsers();
      expect(userTracker.callCount, equals(0));
    });

    test('boundary: first page of multi-page — fetch triggered', () async {
      final (personaProvider, personaTracker) =
          await _createPersonaProviderAtPage(page: 1, totalPages: 5);
      await personaProvider.fetchMorePersonas();
      expect(personaTracker.callCount, equals(1));
      expect(personaTracker.calls.first.queryParameters['page'], equals(2));

      final (userProvider, userTracker) =
          await _createUserProviderAtPage(page: 1, totalPages: 5);
      await userProvider.fetchMoreUsers();
      expect(userTracker.callCount, equals(1));
      expect(userTracker.calls.first.queryParameters['page'], equals(2));
    });

    test('boundary: last page (page == totalPages) — no fetch', () async {
      final (personaProvider, personaTracker) =
          await _createPersonaProviderAtPage(page: 10, totalPages: 10);
      await personaProvider.fetchMorePersonas();
      expect(personaTracker.callCount, equals(0));

      final (userProvider, userTracker) =
          await _createUserProviderAtPage(page: 10, totalPages: 10);
      await userProvider.fetchMoreUsers();
      expect(userTracker.callCount, equals(0));
    });

    test('boundary: page exceeds totalPages — no fetch', () async {
      final (personaProvider, personaTracker) =
          await _createPersonaProviderAtPage(page: 15, totalPages: 10);
      await personaProvider.fetchMorePersonas();
      expect(personaTracker.callCount, equals(0));

      final (userProvider, userTracker) =
          await _createUserProviderAtPage(page: 15, totalPages: 10);
      await userProvider.fetchMoreUsers();
      expect(userTracker.callCount, equals(0));
    });
  });
}
