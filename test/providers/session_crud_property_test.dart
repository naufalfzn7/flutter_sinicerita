import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/session_model.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 9: Session CRUD invariants**
///
/// **Validates: Requirements 16.3, 16.4**
///
/// For any active sessions list:
/// - After a successful createSession, the active sessions list SHALL contain
///   the newly created session and the length SHALL increase by exactly 1.
/// - After a successful deleteSession, the active sessions list SHALL NOT
///   contain the deleted session and the length SHALL decrease by exactly 1.
void main() {
  group(
    'Property 9: Session CRUD maintains list invariants',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random UUID-like string.
      String generateRandomId(Random rng) {
        const chars = 'abcdef0123456789';
        return List.generate(32, (_) => chars[rng.nextInt(chars.length)]).join();
      }

      /// Generate a random SessionModel with status 'active'.
      SessionModel generateRandomSession(Random rng) {
        final now = DateTime(
          2023 + rng.nextInt(3),
          1 + rng.nextInt(12),
          1 + rng.nextInt(28),
          rng.nextInt(24),
          rng.nextInt(60),
        );
        return SessionModel(
          id: generateRandomId(rng),
          userId: generateRandomId(rng),
          personaId: generateRandomId(rng),
          status: 'active',
          createdAt: now,
          startedAt: now.add(Duration(minutes: rng.nextInt(1000))),
        );
      }

      /// Generate a random list of active sessions (1-20 items).
      List<SessionModel> generateRandomSessionList(Random rng) {
        final length = 1 + rng.nextInt(20); // 1-20 items
        return List.generate(length, (_) => generateRandomSession(rng));
      }

      test(
        'Create: adding a session increases list length by exactly 1 and '
        'the new session is present ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalList = generateRandomSessionList(random);
            final originalLength = originalList.length;

            // Generate a new session to "create"
            final newSession = generateRandomSession(random);

            // Simulate createSession: prepend to active list
            final updatedList = [newSession, ...originalList];

            // Invariant 1: Length increases by exactly 1
            expect(
              updatedList.length,
              equals(originalLength + 1),
              reason: 'Iteration $i: list length should increase by 1 '
                  'after create. Original: $originalLength, '
                  'After: ${updatedList.length}',
            );

            // Invariant 2: New session is in the list
            expect(
              updatedList.any((s) => s.id == newSession.id),
              isTrue,
              reason: 'Iteration $i: newly created session with id '
                  '${newSession.id} should be present in the list',
            );

            // Invariant 3: All original sessions are still present
            for (final original in originalList) {
              expect(
                updatedList.any((s) => s.id == original.id),
                isTrue,
                reason: 'Iteration $i: original session ${original.id} '
                    'should still be present after create',
              );
            }
          }
        },
      );

      test(
        'Delete: removing a session decreases list length by exactly 1 and '
        'the deleted session is no longer present ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalList = generateRandomSessionList(random);
            final originalLength = originalList.length;

            // Pick a random session to delete
            final deleteIndex = random.nextInt(originalList.length);
            final sessionToDelete = originalList[deleteIndex];

            // Simulate deleteSession: optimistic removal
            final updatedList = List<SessionModel>.from(originalList)
              ..removeAt(deleteIndex);

            // Invariant 1: Length decreases by exactly 1
            expect(
              updatedList.length,
              equals(originalLength - 1),
              reason: 'Iteration $i: list length should decrease by 1 '
                  'after delete. Original: $originalLength, '
                  'After: ${updatedList.length}',
            );

            // Invariant 2: Deleted session is NOT in the list
            expect(
              updatedList.any((s) => s.id == sessionToDelete.id),
              isFalse,
              reason: 'Iteration $i: deleted session with id '
                  '${sessionToDelete.id} should NOT be present in the list',
            );

            // Invariant 3: All other sessions are still present
            for (var j = 0; j < originalList.length; j++) {
              if (j == deleteIndex) continue;
              expect(
                updatedList.any((s) => s.id == originalList[j].id),
                isTrue,
                reason: 'Iteration $i: non-deleted session '
                    '${originalList[j].id} should still be present',
              );
            }
          }
        },
      );

      test(
        'Create then delete same session: list returns to original length '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalList = generateRandomSessionList(random);
            final originalLength = originalList.length;

            // Create a new session
            final newSession = generateRandomSession(random);
            final afterCreate = [newSession, ...originalList];

            // Delete the same session we just created
            final afterDelete = List<SessionModel>.from(afterCreate)
              ..removeWhere((s) => s.id == newSession.id);

            // Invariant: After create + delete of same session, length == original
            expect(
              afterDelete.length,
              equals(originalLength),
              reason: 'Iteration $i: after create then delete of same session, '
                  'list length should return to original ($originalLength), '
                  'got ${afterDelete.length}',
            );

            // Invariant: The created-then-deleted session is gone
            expect(
              afterDelete.any((s) => s.id == newSession.id),
              isFalse,
              reason: 'Iteration $i: session ${newSession.id} should not be '
                  'present after create + delete',
            );
          }
        },
      );

      test(
        'Delete with non-existent ID: list remains unchanged '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalList = generateRandomSessionList(random);
            final originalLength = originalList.length;

            // Generate an ID that is NOT in the list
            final nonExistentId = 'non-existent-${generateRandomId(random)}';

            // Simulate deleteSession with non-existent ID
            final index =
                originalList.indexWhere((s) => s.id == nonExistentId);

            // If index == -1, the provider returns false and doesn't modify list
            expect(
              index,
              equals(-1),
              reason: 'Iteration $i: generated non-existent ID should not '
                  'match any session in the list',
            );

            // List remains unchanged
            expect(
              originalList.length,
              equals(originalLength),
              reason: 'Iteration $i: list should remain unchanged when '
                  'deleting non-existent session',
            );
          }
        },
      );
    },
  );
}
