import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/api/api_endpoints.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/providers/session_provider.dart';

// ─── Manual Mocks ─────────────────────────────────────────────────────────────

/// In-memory SecureStorage mock (same pattern as auth_provider_test).
class MockSecureStorage implements SecureStorage {
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

/// Mock ApiClient that exposes a Dio instance with a custom HttpClientAdapter.
class MockApiClient implements ApiClient {
  final MockSecureStorage _mockStorage;
  final Dio _dio;

  MockApiClient({required MockSecureStorage mockStorage, Dio? dio})
      : _mockStorage = mockStorage,
        _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://test.local'));

  @override
  SecureStorage get storage => _mockStorage;

  @override
  Dio get dio => _dio;
}

/// A custom HttpClientAdapter that lets us define responses per request.
class MockHttpClientAdapter implements HttpClientAdapter {
  final List<MockResponse> _responses = [];

  void addResponse({
    required String path,
    required String method,
    int statusCode = 200,
    dynamic data,
    DioException? dioException,
  }) {
    _responses.add(MockResponse(
      path: path,
      method: method.toUpperCase(),
      statusCode: statusCode,
      data: data,
      dioException: dioException,
    ));
  }

  void clear() => _responses.clear();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final match = _responses.firstWhere(
      (r) =>
          options.path.contains(r.path) &&
          options.method.toUpperCase() == r.method,
      orElse: () => throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'No mock response for ${options.method} ${options.path}',
      ),
    );

    if (match.dioException != null) {
      throw match.dioException!;
    }

    final jsonStr = jsonEncode(match.data);
    return ResponseBody.fromString(
      jsonStr,
      match.statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class MockResponse {
  final String path;
  final String method;
  final int statusCode;
  final dynamic data;
  final DioException? dioException;

  MockResponse({
    required this.path,
    required this.method,
    this.statusCode = 200,
    this.data,
    this.dioException,
  });
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockSecureStorage mockStorage;
  late MockApiClient mockApiClient;
  late MockHttpClientAdapter mockAdapter;
  late SessionProvider provider;

  setUp(() {
    mockStorage = MockSecureStorage();
    mockAdapter = MockHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = mockAdapter;
    mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
    provider = SessionProvider(apiClient: mockApiClient);
  });

  // ─── Initial State ──────────────────────────────────────────────────────────

  group('Initial State', () {
    test('messages is empty', () {
      expect(provider.messages, isEmpty);
    });

    test('isTyping is false', () {
      expect(provider.isTyping, isFalse);
    });

    test('isSendingMessage is false', () {
      expect(provider.isSendingMessage, isFalse);
    });
  });

  // ─── fetchMessages ──────────────────────────────────────────────────────────

  group('fetchMessages', () {
    const sessionId = 'test-session-id';

    test('success: messages terisi, isLoading false', () async {
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'GET',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Messages retrieved',
          'data': [
            {
              'id': 'msg-1',
              'sessionId': sessionId,
              'role': 'user',
              'content': 'Halo',
              'createdAt': '2024-01-15T10:30:00.000Z',
            },
            {
              'id': 'msg-2',
              'sessionId': sessionId,
              'role': 'model',
              'content': 'Hai! Ada yang bisa saya bantu?',
              'createdAt': '2024-01-15T10:30:01.000Z',
            },
          ],
          'meta': {
            'total': 2,
            'page': 1,
            'limit': 50,
            'totalPages': 1,
          },
        },
      );

      await provider.fetchMessages(sessionId);

      expect(provider.messages.length, 2);
      expect(provider.messages[0].id, 'msg-1');
      expect(provider.messages[0].role, 'user');
      expect(provider.messages[1].id, 'msg-2');
      expect(provider.messages[1].role, 'model');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('success: messages sorted ascending by createdAt', () async {
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'GET',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Messages retrieved',
          'data': [
            {
              'id': 'msg-2',
              'sessionId': sessionId,
              'role': 'model',
              'content': 'Reply',
              'createdAt': '2024-01-15T10:31:00.000Z',
            },
            {
              'id': 'msg-1',
              'sessionId': sessionId,
              'role': 'user',
              'content': 'Hello',
              'createdAt': '2024-01-15T10:30:00.000Z',
            },
          ],
          'meta': {
            'total': 2,
            'page': 1,
            'limit': 50,
            'totalPages': 1,
          },
        },
      );

      await provider.fetchMessages(sessionId);

      expect(provider.messages[0].id, 'msg-1');
      expect(provider.messages[1].id, 'msg-2');
    });

    test('error: errorMessage terisi, isLoading false', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessionMessages(sessionId),
      );
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'GET',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 403,
            data: {
              'success': false,
              'message': 'Akses ditolak: sesi bukan milik Anda',
            },
          ),
        ),
      );

      await provider.fetchMessages(sessionId);

      expect(provider.errorMessage, 'Akses ditolak: sesi bukan milik Anda');
      expect(provider.isLoading, isFalse);
      expect(provider.messages, isEmpty);
    });

    test('empty: messages kosong, tidak error', () async {
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'GET',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Messages retrieved',
          'data': [],
          'meta': {
            'total': 0,
            'page': 1,
            'limit': 50,
            'totalPages': 0,
          },
        },
      );

      await provider.fetchMessages(sessionId);

      expect(provider.messages, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('network error: errorMessage terisi', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessionMessages(sessionId),
      );
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'GET',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await provider.fetchMessages(sessionId);

      expect(
        provider.errorMessage,
        'Koneksi timeout. Periksa jaringan Anda.',
      );
      expect(provider.isLoading, isFalse);
    });
  });

  // ─── sendMessage ────────────────────────────────────────────────────────────

  group('sendMessage', () {
    const sessionId = 'test-session-id';
    const content = 'Halo, saya ingin cerita';

    test('success: userMessage + aiReply ditambahkan', () async {
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'POST',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Message sent',
          'data': {
            'userMessage': {
              'id': 'msg-user-1',
              'sessionId': sessionId,
              'role': 'user',
              'content': content,
              'createdAt': '2024-01-15T10:30:00.000Z',
            },
            'aiReply': {
              'id': 'msg-ai-1',
              'sessionId': sessionId,
              'role': 'model',
              'content': 'Tentu, saya siap mendengarkan.',
              'createdAt': '2024-01-15T10:30:01.000Z',
            },
          },
        },
      );

      final result = await provider.sendMessage(sessionId, content);

      expect(result, isNull); // null means success
      expect(provider.messages.length, 2);
      expect(provider.messages[0].id, 'msg-user-1');
      expect(provider.messages[0].role, 'user');
      expect(provider.messages[0].content, content);
      expect(provider.messages[1].id, 'msg-ai-1');
      expect(provider.messages[1].role, 'model');
      expect(provider.isTyping, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('network error: optimistic message dihapus, error state', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessionMessages(sessionId),
      );
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await provider.sendMessage(sessionId, content);

      expect(result, content); // returns content for restore
      expect(provider.messages, isEmpty);
      expect(provider.isTyping, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.errorMessage, 'Tidak dapat terhubung ke server.');
    });

    test('"Sesi sudah selesai": optimistic message dihapus', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessionMessages(sessionId),
      );
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Sesi sudah selesai',
            },
          ),
        ),
      );

      final result = await provider.sendMessage(sessionId, content);

      expect(result, content);
      expect(provider.messages, isEmpty);
      expect(provider.isTyping, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.errorMessage, 'Sesi sudah selesai');
    });

    test('"Akses ditolak": optimistic message dihapus', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessionMessages(sessionId),
      );
      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 403,
            data: {
              'success': false,
              'message': 'Akses ditolak: sesi bukan milik Anda',
            },
          ),
        ),
      );

      final result = await provider.sendMessage(sessionId, content);

      expect(result, content);
      expect(provider.messages, isEmpty);
      expect(provider.isTyping, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.errorMessage, 'Akses ditolak: sesi bukan milik Anda');
    });

    test('state transitions: isSendingMessage and isTyping during send',
        () async {
      // Track state transitions via listener
      final states = <Map<String, dynamic>>[];
      provider.addListener(() {
        states.add({
          'isSendingMessage': provider.isSendingMessage,
          'isTyping': provider.isTyping,
          'messagesCount': provider.messages.length,
        });
      });

      mockAdapter.addResponse(
        path: '/api/sessions/$sessionId/messages',
        method: 'POST',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'Message sent',
          'data': {
            'userMessage': {
              'id': 'msg-user-1',
              'sessionId': sessionId,
              'role': 'user',
              'content': content,
              'createdAt': '2024-01-15T10:30:00.000Z',
            },
            'aiReply': {
              'id': 'msg-ai-1',
              'sessionId': sessionId,
              'role': 'model',
              'content': 'Reply',
              'createdAt': '2024-01-15T10:30:01.000Z',
            },
          },
        },
      );

      await provider.sendMessage(sessionId, content);

      // First notification: isSendingMessage = true, errorMessage cleared
      expect(states[0]['isSendingMessage'], isTrue);

      // Second notification: optimistic message added, isTyping = true
      expect(states[1]['isTyping'], isTrue);
      expect(states[1]['messagesCount'], 1);

      // Final notification: success, isTyping = false, isSendingMessage = false
      final lastState = states.last;
      expect(lastState['isTyping'], isFalse);
      expect(lastState['isSendingMessage'], isFalse);
      expect(lastState['messagesCount'], 2);
    });
  });

  // ─── createSession ──────────────────────────────────────────────────────────

  group('createSession', () {
    const personaId = 'persona-123';

    test('success: returns SessionModel', () async {
      mockAdapter.addResponse(
        path: '/api/sessions',
        method: 'POST',
        statusCode: 201,
        data: {
          'success': true,
          'message': 'Session created',
          'data': {
            'id': 'session-new-1',
            'userId': 'user-1',
            'personaId': personaId,
            'status': 'active',
            'startedAt': '2024-01-15T10:00:00.000Z',
            'createdAt': '2024-01-15T10:00:00.000Z',
          },
        },
      );

      final session = await provider.createSession(personaId);

      expect(session, isNotNull);
      expect(session!.id, 'session-new-1');
      expect(session.personaId, personaId);
      expect(session.status, 'active');
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.activeSessions.length, 1);
    });

    test('error: returns null, errorMessage set', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessions,
      );
      mockAdapter.addResponse(
        path: '/api/sessions',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Persona tidak aktif',
            },
          ),
        ),
      );

      final session = await provider.createSession(personaId);

      expect(session, isNull);
      expect(provider.errorMessage, 'Persona tidak aktif');
      expect(provider.isLoading, isFalse);
    });

    test('error "Persona tidak ditemukan": returns null', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessions,
      );
      mockAdapter.addResponse(
        path: '/api/sessions',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 404,
            data: {
              'success': false,
              'message': 'Persona tidak ditemukan',
            },
          ),
        ),
      );

      final session = await provider.createSession(personaId);

      expect(session, isNull);
      expect(provider.errorMessage, 'Persona tidak ditemukan');
      expect(provider.isLoading, isFalse);
    });

    test('network error: returns null, errorMessage set', () async {
      final requestOptions = RequestOptions(
        path: ApiEndpoints.sessions,
      );
      mockAdapter.addResponse(
        path: '/api/sessions',
        method: 'POST',
        dioException: DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final session = await provider.createSession(personaId);

      expect(session, isNull);
      expect(
        provider.errorMessage,
        'Koneksi timeout. Periksa jaringan Anda.',
      );
      expect(provider.isLoading, isFalse);
    });
  });

  // ─── clearChatState ─────────────────────────────────────────────────────────

  group('clearChatState', () {
    test('resets all chat-related state', () async {
      // First, populate some state
      mockAdapter.addResponse(
        path: '/api/sessions/test-session/messages',
        method: 'GET',
        statusCode: 200,
        data: {
          'success': true,
          'message': 'OK',
          'data': [
            {
              'id': 'msg-1',
              'sessionId': 'test-session',
              'role': 'user',
              'content': 'Hello',
              'createdAt': '2024-01-15T10:30:00.000Z',
            },
          ],
          'meta': {'total': 1, 'page': 1, 'limit': 50, 'totalPages': 1},
        },
      );

      await provider.fetchMessages('test-session');
      expect(provider.messages.length, 1);

      // Now clear
      provider.clearChatState();

      expect(provider.messages, isEmpty);
      expect(provider.isTyping, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.currentChatSessionId, isNull);
      expect(provider.errorMessage, isNull);
    });
  });
}
