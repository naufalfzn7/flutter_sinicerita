import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/user_model.dart';

void main() {
  group('UserModel', () {
    final validJson = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'user',
      'points': 50,
      'avatarUrl': 'https://res.cloudinary.com/demo/image/upload/avatar.jpg',
      'createdAt': '2024-01-15T10:30:00.000Z',
    };

    final validJsonNullAvatar = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'role': 'admin',
      'points': 75,
      'avatarUrl': null,
      'createdAt': '2024-06-20T08:00:00.000Z',
    };

    group('fromJson', () {
      test('should parse valid JSON with all fields correctly', () {
        final user = UserModel.fromJson(validJson);

        expect(user.id, '550e8400-e29b-41d4-a716-446655440000');
        expect(user.name, 'John Doe');
        expect(user.email, 'john@example.com');
        expect(user.role, 'user');
        expect(user.points, 50);
        expect(user.avatarUrl,
            'https://res.cloudinary.com/demo/image/upload/avatar.jpg');
        expect(user.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
      });

      test('should handle null avatarUrl without error', () {
        final user = UserModel.fromJson(validJsonNullAvatar);

        expect(user.avatarUrl, isNull);
        expect(user.name, 'Jane Doe');
        expect(user.role, 'admin');
        expect(user.points, 75);
      });

      test('should parse createdAt as DateTime', () {
        final user = UserModel.fromJson(validJson);

        expect(user.createdAt, isA<DateTime>());
        expect(user.createdAt.year, 2024);
        expect(user.createdAt.month, 1);
        expect(user.createdAt.day, 15);
      });
    });

    group('toJson', () {
      test('should serialize all fields to Map', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          role: 'user',
          points: 30,
          avatarUrl: 'https://example.com/avatar.png',
          createdAt: DateTime.utc(2024, 3, 10, 14, 0),
        );

        final json = user.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], 'Test User');
        expect(json['email'], 'test@example.com');
        expect(json['role'], 'user');
        expect(json['points'], 30);
        expect(json['avatarUrl'], 'https://example.com/avatar.png');
        expect(json['createdAt'], '2024-03-10T14:00:00.000Z');
      });

      test('should serialize null avatarUrl as null', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          role: 'user',
          points: 0,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final json = user.toJson();

        expect(json['avatarUrl'], isNull);
      });

      test('should serialize createdAt as ISO 8601 string', () {
        final user = UserModel(
          id: 'test-id',
          name: 'Test User',
          email: 'test@example.com',
          role: 'user',
          points: 100,
          createdAt: DateTime.utc(2024, 12, 31, 23, 59, 59),
        );

        final json = user.toJson();

        expect(json['createdAt'], '2024-12-31T23:59:59.000Z');
      });
    });

    group('round-trip', () {
      test('fromJson(toJson(model)) should produce equivalent model', () {
        final original = UserModel(
          id: 'round-trip-id',
          name: 'Round Trip',
          email: 'round@trip.com',
          role: 'user',
          points: 42,
          avatarUrl: 'https://example.com/img.jpg',
          createdAt: DateTime.utc(2024, 6, 15, 12, 30),
        );

        final restored = UserModel.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('round-trip with null avatarUrl', () {
        final original = UserModel(
          id: 'null-avatar-id',
          name: 'No Avatar',
          email: 'no@avatar.com',
          role: 'admin',
          points: 0,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final restored = UserModel.fromJson(original.toJson());

        expect(restored, equals(original));
        expect(restored.avatarUrl, isNull);
      });
    });

    group('Equatable', () {
      test('two UserModels with same fields should be equal', () {
        final user1 = UserModel(
          id: 'same-id',
          name: 'Same',
          email: 'same@email.com',
          role: 'user',
          points: 10,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final user2 = UserModel(
          id: 'same-id',
          name: 'Same',
          email: 'same@email.com',
          role: 'user',
          points: 10,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        expect(user1, equals(user2));
      });

      test('two UserModels with different fields should not be equal', () {
        final user1 = UserModel(
          id: 'id-1',
          name: 'User 1',
          email: 'user1@email.com',
          role: 'user',
          points: 10,
          createdAt: DateTime.utc(2024, 1, 1),
        );

        final user2 = UserModel(
          id: 'id-2',
          name: 'User 2',
          email: 'user2@email.com',
          role: 'admin',
          points: 20,
          createdAt: DateTime.utc(2024, 2, 2),
        );

        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
