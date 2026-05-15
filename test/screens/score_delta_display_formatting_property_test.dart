// Feature: tahap-7-session-completion, Property 6: ScoreDelta Display Formatting

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glados/glados.dart';

/// Pure formatting functions extracted for property testing.
/// Mirror the logic in SessionSummaryScreen._getScoreDeltaColor()
/// and SessionSummaryScreen._getScoreDeltaPrefix().

/// Returns the display color for a given scoreDelta:
/// - Green when scoreDelta > 0
/// - Red when scoreDelta < 0
/// - Grey when scoreDelta == 0
Color getScoreDeltaColor(int scoreDelta) {
  if (scoreDelta > 0) return Colors.green;
  if (scoreDelta < 0) return Colors.red;
  return Colors.grey;
}

/// Returns the display prefix for a given scoreDelta:
/// - "+" for positive values
/// - "" (empty) for negative or zero (negative sign is inherent in the number)
String getScoreDeltaPrefix(int scoreDelta) {
  if (scoreDelta > 0) return '+';
  return '';
}

/// Returns the full formatted display string for a scoreDelta value.
/// E.g., "+5" for 5, "-3" for -3, "0" for 0.
String formatScoreDelta(int scoreDelta) {
  final prefix = getScoreDeltaPrefix(scoreDelta);
  return '$prefix$scoreDelta';
}

/// **Validates: Requirements 3.2, 3.7**
void main() {
  group(
    'Feature: tahap-7-session-completion, '
    'Property 6: ScoreDelta Display Formatting',
    () {
      final random = Random(42);
      const iterations = 150;

      // ─── Color Property Tests (Glados) ─────────────────────────────────

      Glados(any.intInRange(1, 21)).test(
        'getScoreDeltaColor returns green for positive scoreDelta (glados)',
        (scoreDelta) {
          expect(
            getScoreDeltaColor(scoreDelta),
            equals(Colors.green),
            reason: 'scoreDelta=$scoreDelta (positive) should be green',
          );
        },
      );

      Glados(any.intInRange(-20, 0)).test(
        'getScoreDeltaColor returns red for negative scoreDelta (glados)',
        (scoreDelta) {
          expect(
            getScoreDeltaColor(scoreDelta),
            equals(Colors.red),
            reason: 'scoreDelta=$scoreDelta (negative) should be red',
          );
        },
      );

      test(
        'getScoreDeltaColor returns grey for zero scoreDelta',
        () {
          expect(
            getScoreDeltaColor(0),
            equals(Colors.grey),
            reason: 'scoreDelta=0 should be grey',
          );
        },
      );

      test(
        'getScoreDeltaColor: green when > 0, red when < 0, grey when == 0 '
        'across $iterations random inputs in [-20, +20]',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate random scoreDelta in [-20, +20]
            final scoreDelta = random.nextInt(41) - 20;
            final color = getScoreDeltaColor(scoreDelta);

            if (scoreDelta > 0) {
              expect(
                color,
                equals(Colors.green),
                reason: 'Iteration $i: scoreDelta=$scoreDelta (positive) '
                    'should be green, got $color',
              );
            } else if (scoreDelta < 0) {
              expect(
                color,
                equals(Colors.red),
                reason: 'Iteration $i: scoreDelta=$scoreDelta (negative) '
                    'should be red, got $color',
              );
            } else {
              expect(
                color,
                equals(Colors.grey),
                reason: 'Iteration $i: scoreDelta=0 should be grey, got $color',
              );
            }
          }
        },
      );

      // ─── Prefix Property Tests (Glados) ────────────────────────────────

      Glados(any.intInRange(1, 21)).test(
        'getScoreDeltaPrefix returns "+" for positive scoreDelta (glados)',
        (scoreDelta) {
          expect(
            getScoreDeltaPrefix(scoreDelta),
            equals('+'),
            reason: 'scoreDelta=$scoreDelta (positive) should have "+" prefix',
          );
        },
      );

      Glados(any.intInRange(-20, 0)).test(
        'getScoreDeltaPrefix returns "" for negative scoreDelta (glados)',
        (scoreDelta) {
          expect(
            getScoreDeltaPrefix(scoreDelta),
            equals(''),
            reason:
                'scoreDelta=$scoreDelta (negative) should have no prefix '
                '(sign is inherent)',
          );
        },
      );

      test(
        'getScoreDeltaPrefix returns "" for zero scoreDelta',
        () {
          expect(
            getScoreDeltaPrefix(0),
            equals(''),
            reason: 'scoreDelta=0 should have no prefix',
          );
        },
      );

      test(
        'getScoreDeltaPrefix: "+" for positive, "" for negative/zero '
        'across $iterations random inputs in [-20, +20]',
        () {
          for (var i = 0; i < iterations; i++) {
            final scoreDelta = random.nextInt(41) - 20;
            final prefix = getScoreDeltaPrefix(scoreDelta);

            if (scoreDelta > 0) {
              expect(
                prefix,
                equals('+'),
                reason: 'Iteration $i: scoreDelta=$scoreDelta (positive) '
                    'should have "+" prefix, got "$prefix"',
              );
            } else {
              expect(
                prefix,
                equals(''),
                reason: 'Iteration $i: scoreDelta=$scoreDelta (non-positive) '
                    'should have no prefix, got "$prefix"',
              );
            }
          }
        },
      );

      // ─── Combined Formatting Property Tests ────────────────────────────

      test(
        'formatScoreDelta produces correct display string '
        'across $iterations random inputs in [-20, +20]',
        () {
          for (var i = 0; i < iterations; i++) {
            final scoreDelta = random.nextInt(41) - 20;
            final formatted = formatScoreDelta(scoreDelta);

            if (scoreDelta > 0) {
              expect(
                formatted,
                equals('+$scoreDelta'),
                reason: 'Iteration $i: scoreDelta=$scoreDelta should format '
                    'as "+$scoreDelta", got "$formatted"',
              );
            } else if (scoreDelta < 0) {
              expect(
                formatted,
                equals('$scoreDelta'),
                reason: 'Iteration $i: scoreDelta=$scoreDelta should format '
                    'as "$scoreDelta" (sign inherent), got "$formatted"',
              );
            } else {
              expect(
                formatted,
                equals('0'),
                reason: 'Iteration $i: scoreDelta=0 should format '
                    'as "0", got "$formatted"',
              );
            }
          }
        },
      );

      Glados(any.intInRange(-20, 21)).test(
        'formatScoreDelta: combined property — color and prefix are consistent '
        'with sign of scoreDelta (glados)',
        (scoreDelta) {
          final color = getScoreDeltaColor(scoreDelta);
          final prefix = getScoreDeltaPrefix(scoreDelta);
          final formatted = formatScoreDelta(scoreDelta);

          // Color consistency
          if (scoreDelta > 0) {
            expect(color, equals(Colors.green));
            expect(prefix, equals('+'));
            expect(formatted, startsWith('+'));
          } else if (scoreDelta < 0) {
            expect(color, equals(Colors.red));
            expect(prefix, equals(''));
            expect(formatted, startsWith('-'));
          } else {
            expect(color, equals(Colors.grey));
            expect(prefix, equals(''));
            expect(formatted, equals('0'));
          }
        },
      );

      // ─── Exhaustive Test Over Full Range ───────────────────────────────

      test(
        'exhaustive: all scoreDelta values in [-20, +20] have correct '
        'color and prefix',
        () {
          for (var scoreDelta = -20; scoreDelta <= 20; scoreDelta++) {
            final color = getScoreDeltaColor(scoreDelta);
            final prefix = getScoreDeltaPrefix(scoreDelta);
            final formatted = formatScoreDelta(scoreDelta);

            // Color assertions
            if (scoreDelta > 0) {
              expect(color, equals(Colors.green),
                  reason: 'scoreDelta=$scoreDelta should be green');
            } else if (scoreDelta < 0) {
              expect(color, equals(Colors.red),
                  reason: 'scoreDelta=$scoreDelta should be red');
            } else {
              expect(color, equals(Colors.grey),
                  reason: 'scoreDelta=0 should be grey');
            }

            // Prefix assertions
            if (scoreDelta > 0) {
              expect(prefix, equals('+'),
                  reason: 'scoreDelta=$scoreDelta should have "+" prefix');
            } else {
              expect(prefix, equals(''),
                  reason: 'scoreDelta=$scoreDelta should have no prefix');
            }

            // Formatted string assertions
            if (scoreDelta > 0) {
              expect(formatted, equals('+$scoreDelta'));
            } else {
              expect(formatted, equals('$scoreDelta'));
            }
          }
        },
      );
    },
  );
}
