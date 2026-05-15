import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/persona_model.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 7: Vote revert**
///
/// **Validates: Requirements 10.8, 17.4**
///
/// For any persona with initial state (upvotes, downvotes, currentRating),
/// if an optimistic vote update is applied and the API call subsequently fails,
/// the persona state SHALL be reverted to exactly the original
/// (upvotes, downvotes, currentRating) values.
///
/// This tests the pure revert logic — after any optimistic update followed by
/// failure, the state must return to its exact original values.
void main() {
  group(
    'Property 7: Failed vote reverts optimistic update to previous state',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random PersonaModel with random vote state.
      PersonaModel generateRandomPersona(Random rng) {
        final upvotes = rng.nextInt(1001); // 0-1000
        final downvotes = rng.nextInt(1001); // 0-1000

        // Random userRating: null, 'UP', or 'DOWN'
        final ratingOptions = [null, 'UP', 'DOWN'];
        final userRating = ratingOptions[rng.nextInt(3)];

        return PersonaModel(
          id: 'persona-${rng.nextInt(10000)}',
          name: 'Test Persona ${rng.nextInt(100)}',
          description: 'Description for testing',
          isActive: true,
          upvotes: upvotes,
          downvotes: downvotes,
          userRating: userRating,
        );
      }

      /// Generate a random vote action: 'UP' or 'DOWN'.
      String generateRandomAction(Random rng) {
        return rng.nextBool() ? 'UP' : 'DOWN';
      }

      /// Apply optimistic update logic (mirrors PersonaProvider.ratePersona).
      ///
      /// Returns the updated PersonaModel after optimistic update.
      PersonaModel applyOptimisticUpdate(PersonaModel persona, String action) {
        final currentRating = persona.userRating;
        int newUpvotes = persona.upvotes;
        int newDownvotes = persona.downvotes;
        String? newRating;

        if (currentRating == null || currentRating == 'NONE') {
          // No current rating
          if (action == 'UP') {
            newUpvotes += 1;
            newRating = 'UP';
          } else if (action == 'DOWN') {
            newDownvotes += 1;
            newRating = 'DOWN';
          }
        } else if (currentRating == 'UP') {
          if (action == 'DOWN') {
            // Switch from UP to DOWN
            newUpvotes -= 1;
            newDownvotes += 1;
            newRating = 'DOWN';
          } else if (action == 'UP') {
            // Toggle off UP
            newUpvotes -= 1;
            newRating = null;
          }
        } else if (currentRating == 'DOWN') {
          if (action == 'UP') {
            // Switch from DOWN to UP
            newDownvotes -= 1;
            newUpvotes += 1;
            newRating = 'UP';
          } else if (action == 'DOWN') {
            // Toggle off DOWN
            newDownvotes -= 1;
            newRating = null;
          }
        }

        return persona.copyWith(
          upvotes: newUpvotes,
          downvotes: newDownvotes,
          userRating: newRating,
          clearUserRating: newRating == null,
        );
      }

      test(
        'After optimistic update + simulated failure, state reverts to '
        'exact original values ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // 1. Generate random initial state
            final originalPersona = generateRandomPersona(random);
            final action = generateRandomAction(random);

            // 2. Save original state
            final originalUpvotes = originalPersona.upvotes;
            final originalDownvotes = originalPersona.downvotes;
            final originalRating = originalPersona.userRating;

            // 3. Apply optimistic update using copyWith
            final updatedPersona =
                applyOptimisticUpdate(originalPersona, action);

            // 4. Simulate failure → revert to original state
            final revertedPersona = updatedPersona.copyWith(
              upvotes: originalUpvotes,
              downvotes: originalDownvotes,
              userRating: originalRating,
              clearUserRating: originalRating == null,
            );

            // 5. Verify reverted state matches original exactly
            expect(
              revertedPersona.upvotes,
              equals(originalUpvotes),
              reason: 'Iteration $i: upvotes should revert to $originalUpvotes '
                  'after failed vote (action=$action, '
                  'originalRating=$originalRating). '
                  'Got ${revertedPersona.upvotes}',
            );

            expect(
              revertedPersona.downvotes,
              equals(originalDownvotes),
              reason: 'Iteration $i: downvotes should revert to '
                  '$originalDownvotes after failed vote (action=$action, '
                  'originalRating=$originalRating). '
                  'Got ${revertedPersona.downvotes}',
            );

            expect(
              revertedPersona.userRating,
              equals(originalRating),
              reason: 'Iteration $i: userRating should revert to '
                  '$originalRating after failed vote (action=$action). '
                  'Got ${revertedPersona.userRating}',
            );
          }
        },
      );

      test(
        'Revert pattern preserves all non-vote fields unchanged '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalPersona = generateRandomPersona(random);
            final action = generateRandomAction(random);

            // Apply optimistic update
            final updatedPersona =
                applyOptimisticUpdate(originalPersona, action);

            // Simulate failure → revert
            final revertedPersona = updatedPersona.copyWith(
              upvotes: originalPersona.upvotes,
              downvotes: originalPersona.downvotes,
              userRating: originalPersona.userRating,
              clearUserRating: originalPersona.userRating == null,
            );

            // Non-vote fields must remain unchanged
            expect(
              revertedPersona.id,
              equals(originalPersona.id),
              reason: 'Iteration $i: id should remain unchanged after revert',
            );
            expect(
              revertedPersona.name,
              equals(originalPersona.name),
              reason: 'Iteration $i: name should remain unchanged after revert',
            );
            expect(
              revertedPersona.description,
              equals(originalPersona.description),
              reason:
                  'Iteration $i: description should remain unchanged after revert',
            );
            expect(
              revertedPersona.isActive,
              equals(originalPersona.isActive),
              reason:
                  'Iteration $i: isActive should remain unchanged after revert',
            );
          }
        },
      );

      test(
        'Reverted persona equals original persona via Equatable '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final originalPersona = generateRandomPersona(random);
            final action = generateRandomAction(random);

            // Apply optimistic update
            final updatedPersona =
                applyOptimisticUpdate(originalPersona, action);

            // Simulate failure → revert to original state
            final revertedPersona = updatedPersona.copyWith(
              upvotes: originalPersona.upvotes,
              downvotes: originalPersona.downvotes,
              userRating: originalPersona.userRating,
              clearUserRating: originalPersona.userRating == null,
            );

            // Equatable equality: reverted == original
            expect(
              revertedPersona,
              equals(originalPersona),
              reason: 'Iteration $i: reverted persona should equal original '
                  'persona via Equatable. '
                  'Action=$action, originalRating=${originalPersona.userRating}',
            );
          }
        },
      );

      test(
        'Optimistic update produces a different state from original '
        '(confirming revert is meaningful) — '
        'for all valid transitions ($iterations random iterations)',
        () {
          int meaningfulTransitions = 0;

          for (var i = 0; i < iterations; i++) {
            final originalPersona = generateRandomPersona(random);
            final action = generateRandomAction(random);

            // Apply optimistic update
            final updatedPersona =
                applyOptimisticUpdate(originalPersona, action);

            // Check if the update actually changed something
            // (it always should for valid transitions)
            final changed = updatedPersona.upvotes != originalPersona.upvotes ||
                updatedPersona.downvotes != originalPersona.downvotes ||
                updatedPersona.userRating != originalPersona.userRating;

            if (changed) {
              meaningfulTransitions++;

              // The updated state should NOT equal original
              expect(
                updatedPersona,
                isNot(equals(originalPersona)),
                reason: 'Iteration $i: optimistic update should produce a '
                    'different state. Action=$action, '
                    'originalRating=${originalPersona.userRating}',
              );
            }
          }

          // At least 80% of iterations should produce meaningful transitions
          expect(
            meaningfulTransitions,
            greaterThan(iterations * 0.8),
            reason: 'Most random (persona, action) pairs should produce '
                'a meaningful state change. Got $meaningfulTransitions '
                'out of $iterations',
          );
        },
      );
    },
  );
}
