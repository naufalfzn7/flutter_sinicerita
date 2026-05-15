// Feature: session-detail-completed
// Property 1: Session detail response parsing preserves all fields

import 'dart:math';

import 'package:glados/glados.dart';

import 'package:sinicerita/models/persona_model.dart';
import 'package:sinicerita/models/session_model.dart';

/// Custom generators for session detail property tests.
extension SessionDetailParsingGenerators on Any {
  /// Generates a valid ISO 8601 DateTime string with millisecond precision.
  Generator<String> get isoDateTimeString => any.positiveIntOrZero.map(
        (i) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            // Generate timestamps between 2020-01-01 and 2030-01-01
            1577836800000 + (i % 315360000000),
            isUtc: true,
          );
          return dt.toIso8601String();
        },
      );

  /// Generates a non-empty alphanumeric string suitable for IDs.
  Generator<String> get uuidLikeString => any.nonEmptyLetterOrDigits;

  /// Generates a valid session status.
  Generator<String> get sessionStatus => any.choose(['active', 'completed']);

  /// Generates a scoreDelta in valid range [-20, +20].
  Generator<int> get scoreDelta => any.intInRange(-20, 21);

  /// Generates a non-negative integer for upvotes/downvotes.
  Generator<int> get nonNegativeInt => any.intInRange(0, 1000);
}

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Property 1: Session detail response parsing preserves all fields
  // **Validates: Requirements 1.3**
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'Property 1: Session detail response parsing preserves all fields',
    () {
      /// For any valid session detail JSON with id, status, scoreDelta,
      /// analysisSummary, startedAt, completedAt, and embedded persona,
      /// parsing via SessionModel.fromJson and PersonaModel.fromJson
      /// preserves all field values.

      test(
        'SessionModel.fromJson preserves all fields across 100 random inputs',
        () {
          final random = Random(42);

          for (var i = 0; i < 100; i++) {
            // Generate random field values
            final id = _generateRandomId(random);
            final personaId = _generateRandomId(random);
            final status = random.nextBool() ? 'completed' : 'active';
            final scoreDelta = random.nextInt(41) - 20; // [-20, +20]
            final analysisSummary = _generateRandomString(random, 10, 200);
            final createdAtDt = _generateRandomDateTime(random);
            final startedAtDt = _generateRandomDateTime(random);
            final completedAtDt = _generateRandomDateTime(random);

            final createdAt = createdAtDt.toIso8601String();
            final startedAt = startedAtDt.toIso8601String();
            final completedAt = completedAtDt.toIso8601String();

            final json = <String, dynamic>{
              'id': id,
              'personaId': personaId,
              'status': status,
              'scoreDelta': scoreDelta,
              'analysisSummary': analysisSummary,
              'createdAt': createdAt,
              'startedAt': startedAt,
              'completedAt': completedAt,
            };

            final model = SessionModel.fromJson(json);

            expect(
              model.id,
              equals(id),
              reason: 'Iteration $i: id should be preserved. '
                  'Expected "$id", got "${model.id}"',
            );
            expect(
              model.personaId,
              equals(personaId),
              reason: 'Iteration $i: personaId should be preserved. '
                  'Expected "$personaId", got "${model.personaId}"',
            );
            expect(
              model.status,
              equals(status),
              reason: 'Iteration $i: status should be preserved. '
                  'Expected "$status", got "${model.status}"',
            );
            expect(
              model.scoreDelta,
              equals(scoreDelta),
              reason: 'Iteration $i: scoreDelta should be preserved. '
                  'Expected $scoreDelta, got ${model.scoreDelta}',
            );
            expect(
              model.analysisSummary,
              equals(analysisSummary),
              reason: 'Iteration $i: analysisSummary should be preserved.',
            );
            expect(
              model.createdAt,
              equals(DateTime.parse(createdAt)),
              reason: 'Iteration $i: createdAt should be preserved.',
            );
            expect(
              model.startedAt,
              equals(DateTime.parse(startedAt)),
              reason: 'Iteration $i: startedAt should be preserved.',
            );
            expect(
              model.completedAt,
              equals(DateTime.parse(completedAt)),
              reason: 'Iteration $i: completedAt should be preserved.',
            );
          }
        },
      );

      test(
        'PersonaModel.fromJson preserves all fields across 100 random inputs',
        () {
          final random = Random(42);

          for (var i = 0; i < 100; i++) {
            // Generate random persona field values
            final id = _generateRandomId(random);
            final name = _generateRandomString(random, 3, 50);
            final description = _generateRandomString(random, 10, 200);
            final avatarUrl = 'https://example.com/${_generateRandomId(random)}';
            final isActive = random.nextBool();
            final upvotes = random.nextInt(500);
            final downvotes = random.nextInt(100);

            final json = <String, dynamic>{
              'id': id,
              'name': name,
              'description': description,
              'avatarUrl': avatarUrl,
              'isActive': isActive,
              'upvotes': upvotes,
              'downvotes': downvotes,
            };

            final model = PersonaModel.fromJson(json);

            expect(
              model.id,
              equals(id),
              reason: 'Iteration $i: id should be preserved. '
                  'Expected "$id", got "${model.id}"',
            );
            expect(
              model.name,
              equals(name),
              reason: 'Iteration $i: name should be preserved. '
                  'Expected "$name", got "${model.name}"',
            );
            expect(
              model.description,
              equals(description),
              reason: 'Iteration $i: description should be preserved.',
            );
            expect(
              model.avatarUrl,
              equals(avatarUrl),
              reason: 'Iteration $i: avatarUrl should be preserved. '
                  'Expected "$avatarUrl", got "${model.avatarUrl}"',
            );
            expect(
              model.isActive,
              equals(isActive),
              reason: 'Iteration $i: isActive should be preserved. '
                  'Expected $isActive, got ${model.isActive}',
            );
            expect(
              model.upvotes,
              equals(upvotes),
              reason: 'Iteration $i: upvotes should be preserved. '
                  'Expected $upvotes, got ${model.upvotes}',
            );
            expect(
              model.downvotes,
              equals(downvotes),
              reason: 'Iteration $i: downvotes should be preserved. '
                  'Expected $downvotes, got ${model.downvotes}',
            );
          }
        },
      );

      // Glados-based property test for SessionModel parsing
      Glados3(any.uuidLikeString, any.sessionStatus, any.scoreDelta).test(
        'SessionModel.fromJson preserves id, status, and scoreDelta '
        'for any valid combination',
        (id, status, scoreDelta) {
          final json = <String, dynamic>{
            'id': id,
            'personaId': 'persona-123',
            'status': status,
            'scoreDelta': scoreDelta,
            'analysisSummary': 'Test summary',
            'createdAt': '2024-01-15T10:00:00.000Z',
            'startedAt': '2024-01-15T10:00:00.000Z',
            'completedAt': '2024-01-15T11:00:00.000Z',
          };

          final model = SessionModel.fromJson(json);

          expect(model.id, equals(id));
          expect(model.status, equals(status));
          expect(model.scoreDelta, equals(scoreDelta));
        },
      );

      // Glados-based property test for PersonaModel parsing
      Glados3(any.uuidLikeString, any.nonEmptyLetterOrDigits, any.nonNegativeInt)
          .test(
        'PersonaModel.fromJson preserves id, name, and upvotes '
        'for any valid combination',
        (id, name, upvotes) {
          final json = <String, dynamic>{
            'id': id,
            'name': name,
            'description': 'A test description',
            'avatarUrl': 'https://example.com/avatar.png',
            'isActive': true,
            'upvotes': upvotes,
            'downvotes': 0,
          };

          final model = PersonaModel.fromJson(json);

          expect(model.id, equals(id));
          expect(model.name, equals(name));
          expect(model.upvotes, equals(upvotes));
        },
      );

      // Combined test: full session detail response with embedded persona
      test(
        'Full session detail response with embedded persona preserves '
        'all fields across 100 random inputs',
        () {
          final random = Random(99);

          for (var i = 0; i < 100; i++) {
            // Generate session fields
            final sessionId = _generateRandomId(random);
            final personaId = _generateRandomId(random);
            final status = random.nextBool() ? 'completed' : 'active';
            final scoreDelta = random.nextInt(41) - 20;
            final analysisSummary = _generateRandomString(random, 10, 300);
            final createdAt = _generateRandomDateTime(random).toIso8601String();
            final startedAt = _generateRandomDateTime(random).toIso8601String();
            final completedAt =
                _generateRandomDateTime(random).toIso8601String();

            // Generate persona fields
            final personaName = _generateRandomString(random, 3, 30);
            final personaDescription = _generateRandomString(random, 10, 100);
            final personaAvatarUrl =
                'https://cdn.example.com/${_generateRandomId(random)}.jpg';
            final personaIsActive = random.nextBool();
            final personaUpvotes = random.nextInt(500);
            final personaDownvotes = random.nextInt(100);

            // Build the full API response data shape
            final sessionJson = <String, dynamic>{
              'id': sessionId,
              'personaId': personaId,
              'status': status,
              'scoreDelta': scoreDelta,
              'analysisSummary': analysisSummary,
              'createdAt': createdAt,
              'startedAt': startedAt,
              'completedAt': completedAt,
            };

            final personaJson = <String, dynamic>{
              'id': personaId,
              'name': personaName,
              'description': personaDescription,
              'avatarUrl': personaAvatarUrl,
              'isActive': personaIsActive,
              'upvotes': personaUpvotes,
              'downvotes': personaDownvotes,
            };

            // Parse both models (as the provider would)
            final sessionModel = SessionModel.fromJson(sessionJson);
            final personaModel = PersonaModel.fromJson(personaJson);

            // Verify SessionModel fields
            expect(sessionModel.id, equals(sessionId),
                reason: 'Iteration $i: session id mismatch');
            expect(sessionModel.personaId, equals(personaId),
                reason: 'Iteration $i: personaId mismatch');
            expect(sessionModel.status, equals(status),
                reason: 'Iteration $i: status mismatch');
            expect(sessionModel.scoreDelta, equals(scoreDelta),
                reason: 'Iteration $i: scoreDelta mismatch');
            expect(sessionModel.analysisSummary, equals(analysisSummary),
                reason: 'Iteration $i: analysisSummary mismatch');
            expect(sessionModel.createdAt, equals(DateTime.parse(createdAt)),
                reason: 'Iteration $i: createdAt mismatch');
            expect(sessionModel.startedAt, equals(DateTime.parse(startedAt)),
                reason: 'Iteration $i: startedAt mismatch');
            expect(
                sessionModel.completedAt, equals(DateTime.parse(completedAt)),
                reason: 'Iteration $i: completedAt mismatch');

            // Verify PersonaModel fields
            expect(personaModel.id, equals(personaId),
                reason: 'Iteration $i: persona id mismatch');
            expect(personaModel.name, equals(personaName),
                reason: 'Iteration $i: persona name mismatch');
            expect(personaModel.description, equals(personaDescription),
                reason: 'Iteration $i: persona description mismatch');
            expect(personaModel.avatarUrl, equals(personaAvatarUrl),
                reason: 'Iteration $i: persona avatarUrl mismatch');
            expect(personaModel.isActive, equals(personaIsActive),
                reason: 'Iteration $i: persona isActive mismatch');
            expect(personaModel.upvotes, equals(personaUpvotes),
                reason: 'Iteration $i: persona upvotes mismatch');
            expect(personaModel.downvotes, equals(personaDownvotes),
                reason: 'Iteration $i: persona downvotes mismatch');
          }
        },
      );

      // Test nullable fields handling
      test(
        'SessionModel.fromJson handles nullable fields correctly '
        'across 100 random inputs',
        () {
          final random = Random(77);

          for (var i = 0; i < 100; i++) {
            final id = _generateRandomId(random);
            final personaId = _generateRandomId(random);
            final status = random.nextBool() ? 'completed' : 'active';
            final createdAt =
                _generateRandomDateTime(random).toIso8601String();

            // Randomly include or exclude nullable fields
            final includeScoreDelta = random.nextBool();
            final includeAnalysisSummary = random.nextBool();
            final includeStartedAt = random.nextBool();
            final includeCompletedAt = random.nextBool();

            final scoreDelta =
                includeScoreDelta ? random.nextInt(41) - 20 : null;
            final analysisSummary = includeAnalysisSummary
                ? _generateRandomString(random, 5, 100)
                : null;
            final startedAt = includeStartedAt
                ? _generateRandomDateTime(random).toIso8601String()
                : null;
            final completedAt = includeCompletedAt
                ? _generateRandomDateTime(random).toIso8601String()
                : null;

            final json = <String, dynamic>{
              'id': id,
              'personaId': personaId,
              'status': status,
              'scoreDelta': scoreDelta,
              'analysisSummary': analysisSummary,
              'createdAt': createdAt,
              'startedAt': startedAt,
              'completedAt': completedAt,
            };

            final model = SessionModel.fromJson(json);

            expect(model.id, equals(id),
                reason: 'Iteration $i: id mismatch');
            expect(model.personaId, equals(personaId),
                reason: 'Iteration $i: personaId mismatch');
            expect(model.status, equals(status),
                reason: 'Iteration $i: status mismatch');
            expect(model.scoreDelta, equals(scoreDelta),
                reason: 'Iteration $i: scoreDelta mismatch '
                    '(expected $scoreDelta, got ${model.scoreDelta})');
            expect(model.analysisSummary, equals(analysisSummary),
                reason: 'Iteration $i: analysisSummary mismatch');
            expect(model.createdAt, equals(DateTime.parse(createdAt)),
                reason: 'Iteration $i: createdAt mismatch');

            if (startedAt != null) {
              expect(model.startedAt, equals(DateTime.parse(startedAt)),
                  reason: 'Iteration $i: startedAt mismatch');
            } else {
              expect(model.startedAt, isNull,
                  reason: 'Iteration $i: startedAt should be null');
            }

            if (completedAt != null) {
              expect(model.completedAt, equals(DateTime.parse(completedAt)),
                  reason: 'Iteration $i: completedAt mismatch');
            } else {
              expect(model.completedAt, isNull,
                  reason: 'Iteration $i: completedAt should be null');
            }
          }
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper functions for random data generation
// ═══════════════════════════════════════════════════════════════════════════════

/// Generates a random UUID-like string.
String _generateRandomId(Random random) {
  const chars = 'abcdef0123456789';
  return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
}

/// Generates a random string of given length range.
String _generateRandomString(Random random, int minLength, int maxLength) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      '0123456789 .,!?-';
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}

/// Generates a random DateTime between 2020 and 2030 (UTC, millisecond precision).
DateTime _generateRandomDateTime(Random random) {
  // Between 2020-01-01 and 2030-01-01
  final offsetMs = random.nextInt(315360000) * 1000;
  return DateTime.fromMillisecondsSinceEpoch(
    1577836800000 + offsetMs,
    isUtc: true,
  );
}
