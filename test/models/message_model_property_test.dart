import 'package:glados/glados.dart';
import 'package:sinicerita/models/message_model.dart';

/// Custom Generator for valid MessageModel instances.
extension MessageModelGenerators on Any {
  /// Generates a valid MessageModel with:
  /// - Non-empty id and sessionId strings
  /// - Role constrained to 'user' or 'model'
  /// - Non-empty content string
  /// - DateTime with millisecond precision (to avoid microsecond loss in ISO 8601 round-trip)
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

  /// Generates DateTime with millisecond precision only (no microseconds).
  /// This avoids precision loss during ISO 8601 serialization round-trip.
  Generator<DateTime> get dateTimeMillis => any.positiveIntOrZero.map(
        (i) => DateTime.fromMillisecondsSinceEpoch(
          // Generate timestamps between 2020-01-01 and 2030-01-01
          1577836800000 + (i % 315360000000),
          isUtc: true,
        ),
      );
}

void main() {
  group('Property 1: MessageModel serialization round-trip', () {
    /// **Validates: Requirements 1.1, 1.2, 1.5, 9.4**
    Glados(any.messageModel).test(
      'MessageModel.fromJson(model.toJson()) == model for all valid instances',
      (model) {
        final json = model.toJson();
        final restored = MessageModel.fromJson(json);

        expect(restored, equals(model));
      },
    );
  });

  group('Property 2: Role getter mutual exclusivity', () {
    /// **Validates: Requirements 1.3, 1.4**
    Glados2(any.nonEmptyLetterOrDigits, any.choose(['user', 'model'])).test(
      'isUser and isModel are mutually exclusive for any valid role',
      (content, role) {
        final model = MessageModel(
          id: 'test-id',
          sessionId: 'test-session',
          role: role,
          content: content,
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        // Mutual exclusivity: exactly one of isUser/isModel is true (XOR)
        expect(
          model.isUser != model.isModel,
          isTrue,
          reason:
              'isUser=${model.isUser} and isModel=${model.isModel} should be mutually exclusive for role="$role"',
        );

        // isUser corresponds to role == 'user'
        expect(model.isUser, equals(role == 'user'));

        // isModel corresponds to role == 'model'
        expect(model.isModel, equals(role == 'model'));
      },
    );
  });

  group('Property 3: Missing field rejection', () {
    /// **Validates: Requirements 1.6**
    ///
    /// For any valid MessageModel JSON map, removing any single required
    /// field should cause fromJson to throw ArgumentError.
    /// Setting any required field to null should also throw ArgumentError.

    const requiredFields = [
      'id',
      'sessionId',
      'role',
      'content',
      'createdAt',
    ];

    Glados(any.messageModel).test(
      'removing any single required field causes fromJson to throw ArgumentError',
      (model) {
        final validJson = model.toJson();

        // Verify the valid JSON actually works
        expect(
          () => MessageModel.fromJson(validJson),
          returnsNormally,
          reason: 'Valid JSON should parse without error',
        );

        // Remove each field one at a time and verify it throws
        for (final field in requiredFields) {
          final jsonWithMissingField = Map<String, dynamic>.from(validJson)
            ..remove(field);

          expect(
            () => MessageModel.fromJson(jsonWithMissingField),
            throwsA(isA<ArgumentError>()),
            reason:
                'fromJson should throw ArgumentError when "$field" is missing',
          );
        }
      },
    );

    Glados(any.messageModel).test(
      'setting any required field to null causes fromJson to throw ArgumentError',
      (model) {
        final validJson = model.toJson();

        // Verify the valid JSON actually works
        expect(
          () => MessageModel.fromJson(validJson),
          returnsNormally,
          reason: 'Valid JSON should parse without error',
        );

        // Set each field to null one at a time and verify it throws
        for (final field in requiredFields) {
          final jsonWithNullField = Map<String, dynamic>.from(validJson)
            ..[field] = null;

          expect(
            () => MessageModel.fromJson(jsonWithNullField),
            throwsA(isA<ArgumentError>()),
            reason:
                'fromJson should throw ArgumentError when "$field" is null',
          );
        }
      },
    );
  });
}
