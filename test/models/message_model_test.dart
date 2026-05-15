import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/message_model.dart';

void main() {
  group('MessageModel', () {
    final validJson = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'sessionId': '660e8400-e29b-41d4-a716-446655440001',
      'role': 'user',
      'content': 'Halo, apa kabar?',
      'createdAt': '2024-01-15T10:30:00.000Z',
    };

    group('fromJson', () {
      test('should parse valid JSON with all fields correctly', () {
        final message = MessageModel.fromJson(validJson);

        expect(message.id, '550e8400-e29b-41d4-a716-446655440000');
        expect(message.sessionId, '660e8400-e29b-41d4-a716-446655440001');
        expect(message.role, 'user');
        expect(message.content, 'Halo, apa kabar?');
        expect(message.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
      });

      test('should throw ArgumentError when id is missing', () {
        final json = Map<String, dynamic>.from(validJson)..remove('id');

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when id is null', () {
        final json = Map<String, dynamic>.from(validJson)..['id'] = null;

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when sessionId is missing', () {
        final json = Map<String, dynamic>.from(validJson)..remove('sessionId');

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when role is null', () {
        final json = Map<String, dynamic>.from(validJson)..['role'] = null;

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when content is missing', () {
        final json = Map<String, dynamic>.from(validJson)..remove('content');

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when createdAt is missing', () {
        final json = Map<String, dynamic>.from(validJson)..remove('createdAt');

        expect(
          () => MessageModel.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('createdAt parsing', () {
      test('should parse ISO 8601 string correctly', () {
        final message = MessageModel.fromJson(validJson);

        expect(message.createdAt, isA<DateTime>());
        expect(message.createdAt.year, 2024);
        expect(message.createdAt.month, 1);
        expect(message.createdAt.day, 15);
        expect(message.createdAt.hour, 10);
        expect(message.createdAt.minute, 30);
        expect(message.createdAt.second, 0);
        expect(message.createdAt.isUtc, isTrue);
      });
    });

    group('isUser getter', () {
      test('should return true when role is user', () {
        final message = MessageModel.fromJson(validJson);

        expect(message.isUser, isTrue);
      });

      test('should return false when role is model', () {
        final json = Map<String, dynamic>.from(validJson)..['role'] = 'model';
        final message = MessageModel.fromJson(json);

        expect(message.isUser, isFalse);
      });
    });

    group('isModel getter', () {
      test('should return true when role is model', () {
        final json = Map<String, dynamic>.from(validJson)..['role'] = 'model';
        final message = MessageModel.fromJson(json);

        expect(message.isModel, isTrue);
      });

      test('should return false when role is user', () {
        final message = MessageModel.fromJson(validJson);

        expect(message.isModel, isFalse);
      });
    });

    group('toJson', () {
      test('should serialize all fields to Map correctly', () {
        final message = MessageModel(
          id: 'test-id',
          sessionId: 'test-session-id',
          role: 'user',
          content: 'Test message content',
          createdAt: DateTime.utc(2024, 3, 10, 14, 0),
        );

        final json = message.toJson();

        expect(json['id'], 'test-id');
        expect(json['sessionId'], 'test-session-id');
        expect(json['role'], 'user');
        expect(json['content'], 'Test message content');
        expect(json['createdAt'], '2024-03-10T14:00:00.000Z');
      });
    });

    group('Equatable', () {
      test('two instances with same fields should be equal', () {
        final message1 = MessageModel(
          id: 'same-id',
          sessionId: 'same-session',
          role: 'user',
          content: 'Same content',
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final message2 = MessageModel(
          id: 'same-id',
          sessionId: 'same-session',
          role: 'user',
          content: 'Same content',
          createdAt: DateTime.utc(2024, 1, 1),
        );

        expect(message1, equals(message2));
      });

      test('two instances with different fields should not be equal', () {
        final message1 = MessageModel(
          id: 'id-1',
          sessionId: 'session-1',
          role: 'user',
          content: 'Content 1',
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final message2 = MessageModel(
          id: 'id-2',
          sessionId: 'session-2',
          role: 'model',
          content: 'Content 2',
          createdAt: DateTime.utc(2024, 2, 2),
        );

        expect(message1, isNot(equals(message2)));
      });
    });
  });
}
