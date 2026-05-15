import 'dart:math';

import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:sinicerita/core/api/api_client.dart';
import 'package:sinicerita/core/storage/secure_storage.dart';
import 'package:sinicerita/models/message_model.dart';
import 'package:sinicerita/providers/session_provider.dart';

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

/// Custom generators for property-based testing.
extension SessionProviderTestGenerators on Any {
  /// Generates DateTime with millisecond precision only (no microseconds).
  Generator<DateTime> get dateTimeMillis => any.positiveIntOrZero.map(
        (i) => DateTime.fromMillisecondsSinceEpoch(
          // Generate timestamps between 2020-01-01 and 2030-01-01
          1577836800000 + (i % 315360000000),
          isUtc: true,
        ),
      );

  /// Generates a valid MessageModel with random fields.
  Generator<MessageModel> get messageModel => combine5(
        any.nonEmptyLetterOrDigits,
        any.nonEmptyLetterOrDigits,
        any.choose(['user', 'model']),
        any.nonEmptyLetterOrDigits,
        any.dateTimeMillis,
        (id, sessionId, role, content, createdAt) => MessageModel(
          id: id,
          sessionId: sessionId,
          role: role,
          content: content,
          createdAt: createdAt,
        ),
      );
}

/// Creates a Dio instance that returns the given messages as a mock response.
Dio _createMockDio(List<MessageModel> messages) {
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
              'message': 'Messages retrieved',
              'data': messages.map((m) => m.toJson()).toList(),
              'meta': {
                'total': messages.length,
                'page': 1,
                'limit': 50,
                'totalPages': 1,
              },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

/// Creates a Dio instance that always throws the given [DioException].
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

/// Creates a SessionProvider with a mocked Dio that returns the given messages.
SessionProvider _createProviderWithMessages(List<MessageModel> messages) {
  final dio = _createMockDio(messages);
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return SessionProvider(apiClient: mockApiClient);
}

/// Creates a SessionProvider with a mocked Dio that always throws.
SessionProvider _createFailingProvider(DioException exception) {
  final dio = _createFailingDio(exception);
  final mockStorage = MockSecureStorage();
  final mockApiClient = MockApiClient(mockStorage: mockStorage, dio: dio);
  return SessionProvider(apiClient: mockApiClient);
}

void main() {
  // â”€â”€â”€ Property 4: Fetch messages produces sorted list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// **Feature: tahap-6-chat-room, Property 4: Fetch messages produces sorted list**
  ///
  /// **Validates: Requirements 2.4, 3.3**
  ///
  /// For any list of messages returned by the backend API (in any order),
  /// after fetchMessages completes successfully, the provider's messages list
  /// shall be sorted in ascending order by createdAt.
  group('Property 4: Fetch messages produces sorted list', () {
    Glados2(any.messageModel, any.messageModel).test(
      'after fetchMessages, messages are sorted ascending by createdAt '
      'for any pair of messages in any order',
      (msg1, msg2) async {
        final inputMessages = [msg2, msg1];
        final provider = _createProviderWithMessages(inputMessages);

        await provider.fetchMessages('test-session-id');

        final result = provider.messages;
        expect(result.length, equals(2));
        expect(
          result[0].createdAt.compareTo(result[1].createdAt) <= 0,
          isTrue,
          reason:
              'messages[0].createdAt (${result[0].createdAt}) should be '
              '<= messages[1].createdAt (${result[1].createdAt})',
        );
      },
    );

    test(
      'fetchMessages sorts messages ascending by createdAt for 100 random iterations',
      () async {
        const int iterations = 100;
        final random = Random(42);

        for (var iter = 0; iter < iterations; iter++) {
          final messageCount = 2 + random.nextInt(19);
          final messages = List.generate(messageCount, (index) {
            final offsetMs =
                random.nextInt(1000000000) * 315 + random.nextInt(1000000);
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              1577836800000 + offsetMs,
              isUtc: true,
            );
            return MessageModel(
              id: 'msg-$iter-$index',
              sessionId: 'session-$iter',
              role: random.nextBool() ? 'user' : 'model',
              content: 'content-$iter-$index',
              createdAt: timestamp,
            );
          });

          final shuffled = List<MessageModel>.from(messages)..shuffle(random);
          final provider = _createProviderWithMessages(shuffled);

          await provider.fetchMessages('session-$iter');

          final result = provider.messages;
          expect(
            result.length,
            equals(messageCount),
            reason: 'Iteration $iter: expected $messageCount messages, '
                'got ${result.length}',
          );

          for (var i = 0; i < result.length - 1; i++) {
            expect(
              result[i].createdAt.compareTo(result[i + 1].createdAt) <= 0,
              isTrue,
              reason: 'Iteration $iter: messages[$i].createdAt '
                  '(${result[i].createdAt}) should be <= '
                  'messages[${i + 1}].createdAt (${result[i + 1].createdAt})',
            );
          }
        }
      },
    );
  });

  // â”€â”€â”€ Property 6: Error state consistency after failed send â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// **Feature: tahap-6-chat-room, Property 6: Error state consistency after failed send**
  ///
  /// **Validates: Requirements 2.8, 4.9**
  ///
  /// For any DioException thrown during sendMessage, the provider shall end
  /// in a consistent state: isTyping is false, isSendingMessage is false,
  /// errorMessage is non-null, and the optimistic user message is removed
  /// from the messages list.
  group('Property 6: Error state consistency after failed send', () {
    const int iterations = 100;
    final random = Random(42);

    /// Generate a random non-empty content string.
    String generateRandomContent(Random rng) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789 ';
      final length = 1 + rng.nextInt(200);
      final result =
          List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
      return result.trim().isEmpty ? 'fallback content' : result;
    }

    /// Generate a random DioExceptionType.
    DioExceptionType generateRandomDioExceptionType(Random rng) {
      const types = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.badResponse,
        DioExceptionType.unknown,
      ];
      return types[rng.nextInt(types.length)];
    }

    /// Generate a random DioException with the given type.
    DioException generateDioException(DioExceptionType type) {
      final requestOptions =
          RequestOptions(path: '/api/sessions/test-session/messages');
      if (type == DioExceptionType.badResponse) {
        return DioException(
          type: type,
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 400,
            data: {'success': false, 'message': 'Sesi sudah selesai'},
          ),
        );
      }
      return DioException(
        type: type,
        requestOptions: requestOptions,
        message: 'Simulated error',
      );
    }

    /// Generate a random session ID.
    String generateRandomSessionId(Random rng) {
      const chars = 'abcdef0123456789';
      return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    }

    test(
      'After sendMessage fails with any DioException, state is consistent: '
      'isTyping=false, isSendingMessage=false, errorMessage!=null, '
      'optimistic message removed ($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final content = generateRandomContent(random);
          final sessionId = generateRandomSessionId(random);
          final exceptionType = generateRandomDioExceptionType(random);
          final exception = generateDioException(exceptionType);

          final provider = _createFailingProvider(exception);

          // Verify initial state
          expect(provider.isTyping, isFalse,
              reason: 'Iteration $i: initial isTyping should be false');
          expect(provider.isSendingMessage, isFalse,
              reason: 'Iteration $i: initial isSendingMessage should be false');
          expect(provider.messages, isEmpty,
              reason: 'Iteration $i: initial messages should be empty');

          // Call sendMessage â€” it should fail
          final result = await provider.sendMessage(sessionId, content);

          // Property: isTyping must be false after error
          expect(
            provider.isTyping,
            isFalse,
            reason: 'Iteration $i (${exceptionType.name}): '
                'isTyping should be false after failed sendMessage',
          );

          // Property: isSendingMessage must be false after error
          expect(
            provider.isSendingMessage,
            isFalse,
            reason: 'Iteration $i (${exceptionType.name}): '
                'isSendingMessage should be false after failed sendMessage',
          );

          // Property: errorMessage must be non-null after error
          expect(
            provider.errorMessage,
            isNotNull,
            reason: 'Iteration $i (${exceptionType.name}): '
                'errorMessage should be non-null after failed sendMessage',
          );

          // Property: errorMessage must be non-empty
          expect(
            provider.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'Iteration $i (${exceptionType.name}): '
                'errorMessage should be non-empty after failed sendMessage',
          );

          // Property: optimistic message must be removed from messages list
          expect(
            provider.messages,
            isEmpty,
            reason: 'Iteration $i (${exceptionType.name}): '
                'messages list should be empty (optimistic message removed) '
                'after failed sendMessage',
          );

          // Property: sendMessage returns the content (for UI to restore)
          expect(
            result,
            equals(content),
            reason: 'Iteration $i (${exceptionType.name}): '
                'sendMessage should return the content string on failure',
          );
        }
      },
    );

    test(
      'After sendMessage fails, no message with optimistic ID prefix remains '
      '($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final content = generateRandomContent(random);
          final sessionId = generateRandomSessionId(random);
          final exceptionType = generateRandomDioExceptionType(random);
          final exception = generateDioException(exceptionType);

          final provider = _createFailingProvider(exception);

          await provider.sendMessage(sessionId, content);

          // No message with 'optimistic_' prefix should remain
          final optimisticMessages = provider.messages
              .where((msg) => msg.id.startsWith('optimistic_'))
              .toList();

          expect(
            optimisticMessages,
            isEmpty,
            reason: 'Iteration $i (${exceptionType.name}): '
                'no optimistic messages should remain after failed sendMessage',
          );
        }
      },
    );

    test(
      'Error state consistency holds regardless of DioException type '
      '(all types tested explicitly)',
      () async {
        const allTypes = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
          DioExceptionType.badResponse,
          DioExceptionType.unknown,
        ];

        for (final type in allTypes) {
          final exception = generateDioException(type);
          final provider = _createFailingProvider(exception);

          final content = 'test message for ${type.name}';
          final sessionId = 'session-${type.name}';

          await provider.sendMessage(sessionId, content);

          // All invariants must hold for every exception type
          expect(provider.isTyping, isFalse,
              reason: '${type.name}: isTyping should be false');
          expect(provider.isSendingMessage, isFalse,
              reason: '${type.name}: isSendingMessage should be false');
          expect(provider.errorMessage, isNotNull,
              reason: '${type.name}: errorMessage should be non-null');
          expect(provider.messages, isEmpty,
              reason: '${type.name}: messages should be empty');
          expect(
            provider.messages.where((m) => m.content == content),
            isEmpty,
            reason:
                '${type.name}: optimistic message with content should be removed',
          );
        }
      },
    );
  });

  // â”€â”€â”€ Property 7: Error state consistency after failed fetch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// **Feature: tahap-6-chat-room, Property 7: Error state consistency after failed fetch**
  ///
  /// **Validates: Requirements 2.9, 3.5**
  ///
  /// For any DioException thrown during fetchMessages, the provider shall end in
  /// a consistent state: isLoading is false and errorMessage is non-null.
  group('Property 7: Error state consistency after failed fetch', () {
    const int iterations = 150;
    final random = Random(42);

    final dioExceptionTypes = [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badResponse,
      DioExceptionType.cancel,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ];

    final badResponseStatusCodes = [
      400, 401, 403, 404, 409, 429, 500, 502, 503,
    ];

    String generateRandomErrorMessage(Random rng) {
      final messages = [
        'Sesi sudah selesai',
        'Akses ditolak: sesi bukan milik Anda',
        'Sesi tidak ditemukan',
        'Too many requests, please try again later',
        'Terjadi kesalahan pada server.',
        'Internal server error',
        'Validation error',
      ];
      return messages[rng.nextInt(messages.length)];
    }

    String generateRandomSessionId(Random rng) {
      const chars = 'abcdef0123456789';
      return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
    }

    DioException generateRandomDioException(Random rng) {
      final type = dioExceptionTypes[rng.nextInt(dioExceptionTypes.length)];
      final requestOptions =
          RequestOptions(path: '/api/sessions/test-id/messages');

      if (type == DioExceptionType.badResponse) {
        final statusCode =
            badResponseStatusCodes[rng.nextInt(badResponseStatusCodes.length)];
        final hasMessage = rng.nextBool();
        final responseData = hasMessage
            ? {'success': false, 'message': generateRandomErrorMessage(rng)}
            : {'success': false};

        return DioException(
          type: type,
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: responseData,
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
      'For any DioException during fetchMessages, isLoading ends as false '
      'and errorMessage is non-null ($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final sessionId = generateRandomSessionId(random);
          final dioException = generateRandomDioException(random);

          final provider = _createFailingProvider(dioException);

          await provider.fetchMessages(sessionId);

          expect(
            provider.isLoading,
            isFalse,
            reason: 'Iteration $i: isLoading should be false after '
                'DioException of type ${dioException.type.name}. '
                'Status code: ${dioException.response?.statusCode}',
          );

          expect(
            provider.errorMessage,
            isNotNull,
            reason: 'Iteration $i: errorMessage should be non-null after '
                'DioException of type ${dioException.type.name}. '
                'Status code: ${dioException.response?.statusCode}',
          );

          expect(
            provider.errorMessage,
            isNotEmpty,
            reason: 'Iteration $i: errorMessage should be a non-empty string '
                'after DioException of type ${dioException.type.name}',
          );
        }
      },
    );

    test(
      'badResponse with backend message preserves exact backend message '
      '($iterations random iterations)',
      () async {
        for (var i = 0; i < iterations; i++) {
          final requestOptions =
              RequestOptions(path: '/api/sessions/test-id/messages');
          final backendMessage = generateRandomErrorMessage(random);
          final statusCode = badResponseStatusCodes[
              random.nextInt(badResponseStatusCodes.length)];

          final dioException = DioException(
            type: DioExceptionType.badResponse,
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: {'success': false, 'message': backendMessage},
            ),
          );

          final provider = _createFailingProvider(dioException);

          await provider.fetchMessages('test-session-id');

          expect(
            provider.errorMessage,
            equals(backendMessage),
            reason: 'Iteration $i: errorMessage should match backend message '
                '"$backendMessage" for status $statusCode. '
                'Got: "${provider.errorMessage}"',
          );

          expect(
            provider.isLoading,
            isFalse,
            reason: 'Iteration $i: isLoading should be false',
          );
        }
      },
    );

    test(
      'Non-badResponse DioExceptions produce known AppException messages '
      '($iterations random iterations)',
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
          DioExceptionType.cancel: 'Terjadi kesalahan. Coba lagi nanti.',
          DioExceptionType.badCertificate:
              'Terjadi kesalahan. Coba lagi nanti.',
          DioExceptionType.unknown: 'Terjadi kesalahan. Coba lagi nanti.',
        };

        final nonBadResponseTypes = dioExceptionTypes
            .where((t) => t != DioExceptionType.badResponse)
            .toList();

        for (var i = 0; i < iterations; i++) {
          final sessionId = generateRandomSessionId(random);
          final type =
              nonBadResponseTypes[random.nextInt(nonBadResponseTypes.length)];

          final dioException = DioException(
            type: type,
            requestOptions:
                RequestOptions(path: '/api/sessions/$sessionId/messages'),
            message: 'Simulated ${type.name} error',
          );

          final provider = _createFailingProvider(dioException);

          await provider.fetchMessages(sessionId);

          expect(
            provider.errorMessage,
            equals(typeToExpectedMessage[type]),
            reason: 'Iteration $i: errorMessage for ${type.name} should be '
                '"${typeToExpectedMessage[type]}". '
                'Got: "${provider.errorMessage}"',
          );

          expect(
            provider.isLoading,
            isFalse,
            reason:
                'Iteration $i: isLoading should be false for ${type.name}',
          );
        }
      },
    );
  });

  // â”€â”€â”€ Property 11: Invalid response data throws AppException â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  group('Property 11: Invalid response data throws AppException', () {
    /// **Validates: Requirements 9.5**
    ///
    /// For any API response where response.data['data'] is null or not the
    /// expected type (List for GET fetchMessages, Map for POST sendMessage),
    /// the provider shall set errorMessage containing "Format response tidak valid".

    const int iterations = 100;

    test(
      'fetchMessages: response.data[\'data\'] that is not a List sets '
      'errorMessage containing "Format response tidak valid" '
      '($iterations random iterations)',
      () async {
        final random = Random(42);

        for (var i = 0; i < iterations; i++) {
          // Generate a random session ID
          const chars = 'abcdef0123456789';
          final sessionId =
              List.generate(24, (_) => chars[random.nextInt(chars.length)])
                  .join();

          // Generate invalid data types for fetchMessages (expects List)
          final invalidTypes = <dynamic>[
            null,
            'some string response',
            random.nextInt(10000),
            {'key': 'value', 'nested': true},
            random.nextBool(),
            random.nextDouble() * 100,
            42,
            'invalid data',
            {'data': 'not a list'},
          ];
          final invalidData = invalidTypes[random.nextInt(invalidTypes.length)];

          // Create a Dio instance that returns invalid data type
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
                      'message': 'Messages retrieved',
                      'data': invalidData,
                      'meta': {
                        'total': 0,
                        'page': 1,
                        'limit': 50,
                        'totalPages': 1,
                      },
                    },
                  ),
                );
              },
            ),
          );

          final mockStorage = MockSecureStorage();
          final mockApiClient = MockApiClient(
            mockStorage: mockStorage,
            dio: dio,
          );
          final provider = SessionProvider(apiClient: mockApiClient);

          await provider.fetchMessages(sessionId);

          // Verify errorMessage is set and contains expected text
          expect(
            provider.errorMessage,
            isNotNull,
            reason: 'Iteration $i: errorMessage should be set when '
                'response data is ${invalidData.runtimeType} '
                '(value: $invalidData) instead of List',
          );
          expect(
            provider.errorMessage,
            contains('Format response tidak valid'),
            reason: 'Iteration $i: errorMessage should contain '
                '"Format response tidak valid" when data is '
                '${invalidData.runtimeType}',
          );

          // Verify loading state is reset
          expect(
            provider.isLoading,
            isFalse,
            reason: 'Iteration $i: isLoading should be false after error',
          );
        }
      },
    );

    test(
      'sendMessage: response.data[\'data\'] that is not a Map sets '
      'errorMessage containing "Format response tidak valid" '
      '($iterations random iterations)',
      () async {
        final random = Random(43); // Different seed from fetchMessages test

        for (var i = 0; i < iterations; i++) {
          // Generate a random session ID
          const chars = 'abcdef0123456789';
          final sessionId =
              List.generate(24, (_) => chars[random.nextInt(chars.length)])
                  .join();
          final content = 'test message ${random.nextInt(1000)}';

          // Generate invalid data types for sendMessage (expects Map)
          final invalidTypes = <dynamic>[
            null,
            'some string response',
            random.nextInt(10000),
            ['item1', 'item2'],
            random.nextBool(),
            random.nextDouble() * 100,
            42,
            'invalid data',
            [1, 2, 3],
          ];
          final invalidData = invalidTypes[random.nextInt(invalidTypes.length)];

          // Create a Dio instance that returns invalid data type
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
                      'message': 'Message sent',
                      'data': invalidData,
                    },
                  ),
                );
              },
            ),
          );

          final mockStorage = MockSecureStorage();
          final mockApiClient = MockApiClient(
            mockStorage: mockStorage,
            dio: dio,
          );
          final provider = SessionProvider(apiClient: mockApiClient);

          await provider.sendMessage(sessionId, content);

          // Verify errorMessage is set and contains expected text
          expect(
            provider.errorMessage,
            isNotNull,
            reason: 'Iteration $i: errorMessage should be set when '
                'response data is ${invalidData.runtimeType} '
                '(value: $invalidData) instead of Map',
          );
          expect(
            provider.errorMessage,
            contains('Format response tidak valid'),
            reason: 'Iteration $i: errorMessage should contain '
                '"Format response tidak valid" when data is '
                '${invalidData.runtimeType}',
          );

          // Verify typing and sending states are reset
          expect(
            provider.isTyping,
            isFalse,
            reason: 'Iteration $i: isTyping should be false after error',
          );
          expect(
            provider.isSendingMessage,
            isFalse,
            reason:
                'Iteration $i: isSendingMessage should be false after error',
          );

          // Verify optimistic message was removed
          expect(
            provider.messages.isEmpty,
            isTrue,
            reason: 'Iteration $i: optimistic message should be removed '
                'after error',
          );
        }
      },
    );
  });
}
