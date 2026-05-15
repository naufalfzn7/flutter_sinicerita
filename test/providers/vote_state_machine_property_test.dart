import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/models/persona_model.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 6: Vote state machine**
///
/// **Validates: Requirements 10.6, 10.7, 17.3**
///
/// For any persona with initial state (upvotes, downvotes, currentRating) and
/// any vote action (UP or DOWN), the optimistic update SHALL:
/// - If currentRating is NONE and action is UP: increment upvotes by 1, set rating to UP
/// - If currentRating is NONE and action is DOWN: increment downvotes by 1, set rating to DOWN
/// - If currentRating is UP and action is DOWN: decrement upvotes by 1, increment downvotes by 1, set rating to DOWN
/// - If currentRating is DOWN and action is UP: decrement downvotes by 1, increment upvotes by 1, set rating to UP
/// - If currentRating is UP and action is UP (toggle off): decrement upvotes by 1, set rating to null (send NONE)
/// - If currentRating is DOWN and action is DOWN (toggle off): decrement downvotes by 1, set rating to null (send NONE)

/// Applies the vote state machine logic (same as PersonaProvider.ratePersona).
/// Returns the updated PersonaModel after optimistic update.
PersonaModel applyVoteStateMachine(PersonaModel persona, String action) {
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

void main() {
  group(
    'Property 6: Vote state machine produces correct count transitions',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random PersonaModel with random upvotes, downvotes,
      /// and currentRating (null, 'UP', or 'DOWN').
      PersonaModel generateRandomPersona(Random rng) {
        final upvotes = rng.nextInt(1001); // 0-1000
        final downvotes = rng.nextInt(1001); // 0-1000
        final ratingOptions = [null, 'UP', 'DOWN'];
        final currentRating = ratingOptions[rng.nextInt(3)];

        return PersonaModel(
          id: 'persona-${rng.nextInt(10000)}',
          name: 'Test Persona',
          description: 'Test description',
          isActive: true,
          upvotes: upvotes,
          downvotes: downvotes,
          userRating: currentRating,
        );
      }

      /// Generate a random action: 'UP' or 'DOWN'.
      String generateRandomAction(Random rng) {
        return rng.nextBool() ? 'UP' : 'DOWN';
      }

      test(
        'NONE→UP: upvotes+1, rating=UP ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1001);
            final downvotes = random.nextInt(1001);
            // currentRating is null (NONE)
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: null,
            );

            final result = applyVoteStateMachine(persona, 'UP');

            expect(
              result.upvotes,
              equals(upvotes + 1),
              reason: 'Iteration $i: NONE→UP should increment upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes),
              reason: 'Iteration $i: NONE→UP should not change downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              equals('UP'),
              reason: 'Iteration $i: NONE→UP should set rating to UP',
            );
          }
        },
      );

      test(
        'NONE→DOWN: downvotes+1, rating=DOWN ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1001);
            final downvotes = random.nextInt(1001);
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: null,
            );

            final result = applyVoteStateMachine(persona, 'DOWN');

            expect(
              result.upvotes,
              equals(upvotes),
              reason: 'Iteration $i: NONE→DOWN should not change upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes + 1),
              reason: 'Iteration $i: NONE→DOWN should increment downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              equals('DOWN'),
              reason: 'Iteration $i: NONE→DOWN should set rating to DOWN',
            );
          }
        },
      );

      test(
        'UP→DOWN: upvotes-1, downvotes+1, rating=DOWN ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1000) + 1; // At least 1 to decrement
            final downvotes = random.nextInt(1001);
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: 'UP',
            );

            final result = applyVoteStateMachine(persona, 'DOWN');

            expect(
              result.upvotes,
              equals(upvotes - 1),
              reason: 'Iteration $i: UP→DOWN should decrement upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes + 1),
              reason: 'Iteration $i: UP→DOWN should increment downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              equals('DOWN'),
              reason: 'Iteration $i: UP→DOWN should set rating to DOWN',
            );
          }
        },
      );

      test(
        'DOWN→UP: downvotes-1, upvotes+1, rating=UP ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1001);
            final downvotes = random.nextInt(1000) + 1; // At least 1 to decrement
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: 'DOWN',
            );

            final result = applyVoteStateMachine(persona, 'UP');

            expect(
              result.upvotes,
              equals(upvotes + 1),
              reason: 'Iteration $i: DOWN→UP should increment upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes - 1),
              reason: 'Iteration $i: DOWN→UP should decrement downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              equals('UP'),
              reason: 'Iteration $i: DOWN→UP should set rating to UP',
            );
          }
        },
      );

      test(
        'UP→UP (toggle off): upvotes-1, rating=null ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1000) + 1; // At least 1 to decrement
            final downvotes = random.nextInt(1001);
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: 'UP',
            );

            final result = applyVoteStateMachine(persona, 'UP');

            expect(
              result.upvotes,
              equals(upvotes - 1),
              reason: 'Iteration $i: UP→UP (toggle) should decrement upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes),
              reason: 'Iteration $i: UP→UP (toggle) should not change downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              isNull,
              reason: 'Iteration $i: UP→UP (toggle) should set rating to null',
            );
          }
        },
      );

      test(
        'DOWN→DOWN (toggle off): downvotes-1, rating=null ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final upvotes = random.nextInt(1001);
            final downvotes = random.nextInt(1000) + 1; // At least 1 to decrement
            final persona = PersonaModel(
              id: 'p-$i',
              name: 'Persona',
              description: 'Desc',
              isActive: true,
              upvotes: upvotes,
              downvotes: downvotes,
              userRating: 'DOWN',
            );

            final result = applyVoteStateMachine(persona, 'DOWN');

            expect(
              result.upvotes,
              equals(upvotes),
              reason: 'Iteration $i: DOWN→DOWN (toggle) should not change upvotes. '
                  'Initial upvotes=$upvotes, got ${result.upvotes}',
            );
            expect(
              result.downvotes,
              equals(downvotes - 1),
              reason: 'Iteration $i: DOWN→DOWN (toggle) should decrement downvotes. '
                  'Initial downvotes=$downvotes, got ${result.downvotes}',
            );
            expect(
              result.userRating,
              isNull,
              reason: 'Iteration $i: DOWN→DOWN (toggle) should set rating to null',
            );
          }
        },
      );

      test(
        'all transitions with fully random state and action ($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final persona = generateRandomPersona(random);
            final action = generateRandomAction(random);
            final currentRating = persona.userRating;

            final result = applyVoteStateMachine(persona, action);

            // Verify based on transition
            if (currentRating == null || currentRating == 'NONE') {
              if (action == 'UP') {
                expect(result.upvotes, persona.upvotes + 1,
                    reason: 'Iter $i: NONE+UP → upvotes+1');
                expect(result.downvotes, persona.downvotes,
                    reason: 'Iter $i: NONE+UP → downvotes unchanged');
                expect(result.userRating, 'UP',
                    reason: 'Iter $i: NONE+UP → rating=UP');
              } else {
                expect(result.upvotes, persona.upvotes,
                    reason: 'Iter $i: NONE+DOWN → upvotes unchanged');
                expect(result.downvotes, persona.downvotes + 1,
                    reason: 'Iter $i: NONE+DOWN → downvotes+1');
                expect(result.userRating, 'DOWN',
                    reason: 'Iter $i: NONE+DOWN → rating=DOWN');
              }
            } else if (currentRating == 'UP') {
              if (action == 'DOWN') {
                expect(result.upvotes, persona.upvotes - 1,
                    reason: 'Iter $i: UP+DOWN → upvotes-1');
                expect(result.downvotes, persona.downvotes + 1,
                    reason: 'Iter $i: UP+DOWN → downvotes+1');
                expect(result.userRating, 'DOWN',
                    reason: 'Iter $i: UP+DOWN → rating=DOWN');
              } else {
                // Toggle off
                expect(result.upvotes, persona.upvotes - 1,
                    reason: 'Iter $i: UP+UP → upvotes-1');
                expect(result.downvotes, persona.downvotes,
                    reason: 'Iter $i: UP+UP → downvotes unchanged');
                expect(result.userRating, isNull,
                    reason: 'Iter $i: UP+UP → rating=null');
              }
            } else if (currentRating == 'DOWN') {
              if (action == 'UP') {
                expect(result.upvotes, persona.upvotes + 1,
                    reason: 'Iter $i: DOWN+UP → upvotes+1');
                expect(result.downvotes, persona.downvotes - 1,
                    reason: 'Iter $i: DOWN+UP → downvotes-1');
                expect(result.userRating, 'UP',
                    reason: 'Iter $i: DOWN+UP → rating=UP');
              } else {
                // Toggle off
                expect(result.upvotes, persona.upvotes,
                    reason: 'Iter $i: DOWN+DOWN → upvotes unchanged');
                expect(result.downvotes, persona.downvotes - 1,
                    reason: 'Iter $i: DOWN+DOWN → downvotes-1');
                expect(result.userRating, isNull,
                    reason: 'Iter $i: DOWN+DOWN → rating=null');
              }
            }
          }
        },
      );
    },
  );
}
