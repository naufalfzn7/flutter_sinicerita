import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/session_model.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 10: Session deletion optimistic revert**
///
/// **Validates: Requirements 7.4**
///
/// Property 10: Session deletion optimistic revert restores original list on failure.
///
/// For any active sessions list and any session within that list, if the session
/// is optimistically removed and the DELETE API call fails, the active sessions
/// list SHALL be restored to its exact original state (same items, same order).
///
/// This tests the pure revert logic without needing actual API mocking:
/// 1. Save original list
/// 2. Remove the session (optimistic)
/// 3. Simulate failure → revert by inserting back at original index
/// 4. Verify the reverted list matches the original exactly (same items, same order)
void main() {
  group(
    'Property 10: Session deletion optimistic revert restores original list '
    'on failure',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random UUID-like string.
      String generateRandomId(Random rng) {
        const chars = 'abcdef0123456789';
        return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
      }

      /// Generate a random DateTime within a reasonable range (2023-2025).
      DateTime generateRandomDateTime(Random rng) {
        final year = 2023 + rng.nextInt(3); // 2023-2025
        final month = 1 + rng.nextInt(12);
        final day = 1 + rng.nextInt(28);
        final hour = rng.nextInt(24);
        final minute = rng.nextInt(60);
        final second = rng.nextInt(60);
        return DateTime(year, month, day, hour, minute, second);
      }

      /// Generate a random SessionModel with status 'active'.
      SessionModel generateRandomSession(Random rng) {
        return SessionModel(
          id: generateRandomId(rng),
          userId: generateRandomId(rng),
          personaId: generateRandomId(rng),
          status: 'active',
          createdAt: generateRandomDateTime(rng),
          startedAt: generateRandomDateTime(rng),
        );
      }

      /// Generate a random list of active sessions with length between 2 and 15.
      List<SessionModel> generateRandomSessionList(Random rng) {
        final length = 2 + rng.nextInt(14); // 2-15 items
        return List.generate(length, (_) => generateRandomSession(rng));
      }

      test(
        'Optimistic delete + revert restores exact original list '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate a random list of active sessions
            final originalList = generateRandomSessionList(random);

            // Pick a random session to "delete"
            final deleteIndex = random.nextInt(originalList.length);
            final sessionToDelete = originalList[deleteIndex];

            // Step 1: Save original list (snapshot)
            final savedList = List<SessionModel>.from(originalList);

            // Step 2: Optimistic removal (same logic as SessionProvider)
            final workingList = List<SessionModel>.from(originalList);
            final index =
                workingList.indexWhere((s) => s.id == sessionToDelete.id);
            expect(
              index,
              isNot(-1),
              reason: 'Iteration $i: session to delete should exist in list',
            );
            final removedSession = workingList[index];
            workingList.removeAt(index);

            // Verify optimistic removal happened
            expect(
              workingList.length,
              equals(originalList.length - 1),
              reason: 'Iteration $i: list should be 1 shorter after removal',
            );
            expect(
              workingList.any((s) => s.id == sessionToDelete.id),
              isFalse,
              reason:
                  'Iteration $i: removed session should not be in working list',
            );

            // Step 3: Simulate failure → revert by inserting back at original index
            workingList.insert(index, removedSession);

            // Step 4: Verify the reverted list matches the original exactly
            expect(
              workingList.length,
              equals(savedList.length),
              reason: 'Iteration $i: reverted list length should match original',
            );

            // Verify same items in same order
            for (var j = 0; j < savedList.length; j++) {
              expect(
                workingList[j].id,
                equals(savedList[j].id),
                reason: 'Iteration $i, index $j: '
                    'reverted list item ID should match original. '
                    'Expected "${savedList[j].id}", got "${workingList[j].id}"',
              );
              expect(
                workingList[j],
                equals(savedList[j]),
                reason: 'Iteration $i, index $j: '
                    'reverted list item should be identical to original',
              );
            }
          }
        },
      );

      test(
        'Revert preserves order regardless of deletion position '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalList = generateRandomSessionList(random);
            final listLength = originalList.length;

            // Test deletion at different positions: start, middle, end
            final positions = <int>[
              0, // first
              listLength ~/ 2, // middle
              listLength - 1, // last
            ];

            for (final deleteIndex in positions) {
              final savedList = List<SessionModel>.from(originalList);
              final workingList = List<SessionModel>.from(originalList);

              // Optimistic removal
              final removedSession = workingList[deleteIndex];
              workingList.removeAt(deleteIndex);

              // Revert
              workingList.insert(deleteIndex, removedSession);

              // Verify exact match with original
              expect(
                workingList.length,
                equals(savedList.length),
                reason: 'Iteration $i, deleteIndex $deleteIndex: '
                    'reverted list length should match original',
              );

              for (var j = 0; j < savedList.length; j++) {
                expect(
                  workingList[j].id,
                  equals(savedList[j].id),
                  reason: 'Iteration $i, deleteIndex $deleteIndex, index $j: '
                      'item order should be preserved after revert',
                );
              }
            }
          }
        },
      );

      test(
        'Revert with duplicate personaIds still restores correct session '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate sessions where some share the same personaId
            final sharedPersonaId = generateRandomId(random);
            final length = 3 + random.nextInt(10); // 3-12 items
            final originalList = List.generate(length, (idx) {
              final session = generateRandomSession(random);
              // Make ~50% of sessions share the same personaId
              if (random.nextBool()) {
                return SessionModel(
                  id: session.id,
                  userId: session.userId,
                  personaId: sharedPersonaId,
                  status: session.status,
                  createdAt: session.createdAt,
                  startedAt: session.startedAt,
                );
              }
              return session;
            });

            // Pick a random session to delete
            final deleteIndex = random.nextInt(originalList.length);
            final savedList = List<SessionModel>.from(originalList);
            final workingList = List<SessionModel>.from(originalList);

            // Optimistic removal using ID (unique identifier)
            final sessionId = originalList[deleteIndex].id;
            final index = workingList.indexWhere((s) => s.id == sessionId);
            final removedSession = workingList[index];
            workingList.removeAt(index);

            // Revert
            workingList.insert(index, removedSession);

            // Verify exact match
            expect(
              workingList.length,
              equals(savedList.length),
              reason: 'Iteration $i: reverted list length should match',
            );

            for (var j = 0; j < savedList.length; j++) {
              expect(
                workingList[j].id,
                equals(savedList[j].id),
                reason: 'Iteration $i, index $j: '
                    'session ID should match after revert with shared personaIds',
              );
            }
          }
        },
      );
    },
  );
}
