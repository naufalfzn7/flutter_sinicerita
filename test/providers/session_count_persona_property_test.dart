import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/session_model.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 8: Session count per persona**
///
/// **Validates: Requirements 10.9**
///
/// For any list of sessions and any target personaId, the session count for
/// that persona SHALL equal the number of sessions in the list whose
/// `personaId` field matches the target.
///
/// This tests the pure filtering logic used in PersonaDetailScreen to show
/// "session count with this persona".
void main() {
  group(
    'Property 8: Session count per persona is correctly computed by filtering',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Pool of persona IDs to randomly assign to sessions.
      final personaIdPool = List.generate(5, (i) => 'persona-$i');

      /// Generate a random SessionModel with a random personaId from the pool.
      SessionModel generateRandomSession(Random rng, int index) {
        final personaId = personaIdPool[rng.nextInt(personaIdPool.length)];
        final baseDate = DateTime(2024, 1, 1);
        final createdAt = baseDate.add(Duration(hours: rng.nextInt(8760)));
        final startedAt = createdAt.add(Duration(minutes: rng.nextInt(1440)));

        return SessionModel(
          id: 'session-$index-${rng.nextInt(99999)}',
          userId: 'user-1',
          personaId: personaId,
          status: rng.nextBool() ? 'active' : 'completed',
          scoreDelta: rng.nextBool() ? rng.nextInt(41) - 20 : null,
          analysisSummary: rng.nextBool() ? 'Summary $index' : null,
          createdAt: createdAt,
          startedAt: startedAt,
          completedAt: rng.nextBool() ? startedAt.add(Duration(hours: 1)) : null,
        );
      }

      /// Pure function that mirrors the filtering logic used in the app:
      /// sessions.where((s) => s.personaId == targetId).length
      int sessionCountForPersona(
          List<SessionModel> sessions, String targetPersonaId) {
        return sessions.where((s) => s.personaId == targetPersonaId).length;
      }

      test(
        'session count matches manual filter count for random sessions and random personaId '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate random list of sessions (0-20 items)
            final sessionCount = random.nextInt(21); // 0-20
            final sessions = List.generate(
              sessionCount,
              (idx) => generateRandomSession(random, idx),
            );

            // Pick a random target personaId from the pool
            final targetId = personaIdPool[random.nextInt(personaIdPool.length)];

            // Compute using the filter function
            final result = sessionCountForPersona(sessions, targetId);

            // Manually count matching items for verification
            var manualCount = 0;
            for (final session in sessions) {
              if (session.personaId == targetId) {
                manualCount++;
              }
            }

            expect(
              result,
              equals(manualCount),
              reason: 'Iteration $i: ${sessions.length} sessions, '
                  'targetId=$targetId — '
                  'expected count=$manualCount, got $result',
            );

            // Also verify the count is within valid bounds
            expect(
              result,
              lessThanOrEqualTo(sessions.length),
              reason: 'Iteration $i: count ($result) should not exceed '
                  'total sessions (${sessions.length})',
            );
            expect(
              result,
              greaterThanOrEqualTo(0),
              reason: 'Iteration $i: count ($result) should be non-negative',
            );
          }
        },
      );

      test(
        'session count is zero when no sessions match the target personaId '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate sessions with personaIds from the pool
            final sessionCount = random.nextInt(20) + 1; // 1-20
            final sessions = List.generate(
              sessionCount,
              (idx) => generateRandomSession(random, idx),
            );

            // Use a personaId that is NOT in the pool
            const nonExistentId = 'persona-non-existent';

            final result = sessionCountForPersona(sessions, nonExistentId);

            expect(
              result,
              equals(0),
              reason: 'Iteration $i: ${sessions.length} sessions — '
                  'expected count=0 for non-existent personaId, got $result',
            );
          }
        },
      );

      test(
        'session count equals total when all sessions belong to the same persona '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final targetId = personaIdPool[random.nextInt(personaIdPool.length)];
            final sessionCount = random.nextInt(20) + 1; // 1-20

            // Generate sessions all with the same personaId
            final baseDate = DateTime(2024, 1, 1);
            final sessions = List.generate(sessionCount, (idx) {
              final createdAt =
                  baseDate.add(Duration(hours: random.nextInt(8760)));
              return SessionModel(
                id: 'session-$idx-${random.nextInt(99999)}',
                userId: 'user-1',
                personaId: targetId,
                status: random.nextBool() ? 'active' : 'completed',
                createdAt: createdAt,
                startedAt: createdAt.add(Duration(minutes: random.nextInt(60))),
              );
            });

            final result = sessionCountForPersona(sessions, targetId);

            expect(
              result,
              equals(sessionCount),
              reason: 'Iteration $i: all $sessionCount sessions have '
                  'personaId=$targetId — expected count=$sessionCount, '
                  'got $result',
            );
          }
        },
      );

      test('empty session list returns zero for any personaId', () {
        final emptyList = <SessionModel>[];

        for (final personaId in personaIdPool) {
          expect(
            sessionCountForPersona(emptyList, personaId),
            equals(0),
            reason: 'Empty list should return 0 for personaId=$personaId',
          );
        }
      });

      test(
        'sum of counts across all persona IDs equals total session count '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final sessionCount = random.nextInt(21); // 0-20
            final sessions = List.generate(
              sessionCount,
              (idx) => generateRandomSession(random, idx),
            );

            // Sum counts for all persona IDs in the pool
            var totalCount = 0;
            for (final personaId in personaIdPool) {
              totalCount += sessionCountForPersona(sessions, personaId);
            }

            expect(
              totalCount,
              equals(sessions.length),
              reason: 'Iteration $i: sum of counts across all persona IDs '
                  '($totalCount) should equal total sessions '
                  '(${sessions.length})',
            );
          }
        },
      );
    },
  );
}
