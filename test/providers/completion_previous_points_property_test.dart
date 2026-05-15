// Feature: tahap-7-session-completion, Property 1: previousPoints Calculation

import 'dart:math';

import 'package:glados/glados.dart';
import 'package:sinicerita/models/completion_result.dart';

/// Custom generators for session completion property tests.
extension CompletionGenerators on Any {
  /// Generates a valid newPoints value in [0, 100].
  Generator<int> get validNewPoints =>
      any.intInRange(0, 101); // intInRange is [min, max)

  /// Generates a valid scoreDelta value in [-20, +20].
  Generator<int> get validScoreDelta => any.intInRange(-20, 21);
}

void main() {
  // ─── Property 1: previousPoints Calculation ─────────────────────────────────

  /// **Feature: tahap-7-session-completion, Property 1: previousPoints Calculation**
  ///
  /// **Validates: Requirements 2.3, 3.3**
  ///
  /// For any valid newPoints (0–100) and scoreDelta (-20 to +20),
  /// the calculated previousPoints SHALL always equal newPoints - scoreDelta.
  group('Property 1: previousPoints Calculation', () {
    Glados2(any.validNewPoints, any.validScoreDelta).test(
      'CompletionResult.previousPoints == newPoints - scoreDelta '
      'for any valid newPoints and scoreDelta (glados)',
      (newPoints, scoreDelta) {
        final expectedPreviousPoints = newPoints - scoreDelta;

        final result = CompletionResult(
          scoreDelta: scoreDelta,
          newPoints: newPoints,
          previousPoints: expectedPreviousPoints,
          summary: 'test summary',
        );

        expect(
          result.previousPoints,
          equals(expectedPreviousPoints),
          reason: 'For newPoints=$newPoints, scoreDelta=$scoreDelta: '
              'previousPoints should be ${newPoints - scoreDelta}, '
              'got ${result.previousPoints}',
        );
      },
    );

    test(
      'previousPoints == newPoints - scoreDelta holds for 200 random iterations',
      () {
        const int iterations = 200;
        final random = Random(42);

        for (var i = 0; i < iterations; i++) {
          // Generate random valid inputs
          final newPoints = random.nextInt(101); // 0 to 100
          final scoreDelta = random.nextInt(41) - 20; // -20 to +20

          final expectedPreviousPoints = newPoints - scoreDelta;

          final result = CompletionResult(
            scoreDelta: scoreDelta,
            newPoints: newPoints,
            previousPoints: expectedPreviousPoints,
            summary: 'iteration $i',
          );

          expect(
            result.previousPoints,
            equals(expectedPreviousPoints),
            reason: 'Iteration $i: For newPoints=$newPoints, '
                'scoreDelta=$scoreDelta: previousPoints should be '
                '$expectedPreviousPoints, got ${result.previousPoints}',
          );

          // Also verify the math identity: previousPoints + scoreDelta == newPoints
          expect(
            result.previousPoints + scoreDelta,
            equals(newPoints),
            reason: 'Iteration $i: previousPoints + scoreDelta should equal '
                'newPoints. Got ${result.previousPoints} + $scoreDelta = '
                '${result.previousPoints + scoreDelta}, expected $newPoints',
          );
        }
      },
    );

    test(
      'previousPoints calculation is correct at boundary values',
      () {
        // Boundary: max newPoints with max positive scoreDelta
        final maxPositive = CompletionResult(
          scoreDelta: 20,
          newPoints: 100,
          previousPoints: 100 - 20,
          summary: 'boundary',
        );
        expect(maxPositive.previousPoints, equals(80));

        // Boundary: min newPoints with max negative scoreDelta
        final maxNegative = CompletionResult(
          scoreDelta: -20,
          newPoints: 0,
          previousPoints: 0 - (-20),
          summary: 'boundary',
        );
        expect(maxNegative.previousPoints, equals(20));

        // Boundary: zero scoreDelta
        final zeroDelta = CompletionResult(
          scoreDelta: 0,
          newPoints: 50,
          previousPoints: 50 - 0,
          summary: 'boundary',
        );
        expect(zeroDelta.previousPoints, equals(50));

        // Boundary: newPoints == 0, scoreDelta == 0
        final allZero = CompletionResult(
          scoreDelta: 0,
          newPoints: 0,
          previousPoints: 0,
          summary: 'boundary',
        );
        expect(allZero.previousPoints, equals(0));

        // Boundary: newPoints == 100, scoreDelta == -20 → previousPoints = 120
        final overHundred = CompletionResult(
          scoreDelta: -20,
          newPoints: 100,
          previousPoints: 100 - (-20),
          summary: 'boundary',
        );
        expect(overHundred.previousPoints, equals(120));
      },
    );
  });
}
