import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/utils/home_helpers.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 2: Score status mapping**
///
/// **Validates: Requirements 3.2, 3.3, 3.4, 3.5**
///
/// For any integer points value in the range [0, 100], the getScoreStatus
/// function SHALL return:
/// - text "Kamu butuh perhatian lebih, yuk cerita" and colorCategory "red"
///   if points is 0–39
/// - text "Keadaanmu cukup stabil, tetap semangat" and colorCategory "yellow"
///   if points is 40–69
/// - text "Keadaanmu baik, pertahankan ya!" and colorCategory "green"
///   if points is 70–100
void main() {
  group(
    'Property 2: Score status mapping returns correct text and color '
    'category for all point values',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      test(
        'correct text and colorCategory for random points in [0, 100] '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final points = random.nextInt(101); // 0-100 inclusive
            final result = getScoreStatus(points);

            if (points >= 0 && points <= 39) {
              expect(
                result.text,
                equals('Kamu butuh perhatian lebih, yuk cerita'),
                reason: 'Iteration $i: points=$points — '
                    'expected red text, got "${result.text}"',
              );
              expect(
                result.colorCategory,
                equals('red'),
                reason: 'Iteration $i: points=$points — '
                    'expected colorCategory "red", got "${result.colorCategory}"',
              );
            } else if (points >= 40 && points <= 69) {
              expect(
                result.text,
                equals('Keadaanmu cukup stabil, tetap semangat'),
                reason: 'Iteration $i: points=$points — '
                    'expected yellow text, got "${result.text}"',
              );
              expect(
                result.colorCategory,
                equals('yellow'),
                reason: 'Iteration $i: points=$points — '
                    'expected colorCategory "yellow", got "${result.colorCategory}"',
              );
            } else {
              // points >= 70 && points <= 100
              expect(
                result.text,
                equals('Keadaanmu baik, pertahankan ya!'),
                reason: 'Iteration $i: points=$points — '
                    'expected green text, got "${result.text}"',
              );
              expect(
                result.colorCategory,
                equals('green'),
                reason: 'Iteration $i: points=$points — '
                    'expected colorCategory "green", got "${result.colorCategory}"',
              );
            }
          }
        },
      );

      // Boundary verification: ensure all boundary values are tested explicitly
      test('boundary values are correctly categorized', () {
        // Red boundaries
        final result0 = getScoreStatus(0);
        expect(result0.colorCategory, 'red');
        expect(result0.text, 'Kamu butuh perhatian lebih, yuk cerita');

        final result39 = getScoreStatus(39);
        expect(result39.colorCategory, 'red');
        expect(result39.text, 'Kamu butuh perhatian lebih, yuk cerita');

        // Yellow boundaries
        final result40 = getScoreStatus(40);
        expect(result40.colorCategory, 'yellow');
        expect(result40.text, 'Keadaanmu cukup stabil, tetap semangat');

        final result69 = getScoreStatus(69);
        expect(result69.colorCategory, 'yellow');
        expect(result69.text, 'Keadaanmu cukup stabil, tetap semangat');

        // Green boundaries
        final result70 = getScoreStatus(70);
        expect(result70.colorCategory, 'green');
        expect(result70.text, 'Keadaanmu baik, pertahankan ya!');

        final result100 = getScoreStatus(100);
        expect(result100.colorCategory, 'green');
        expect(result100.text, 'Keadaanmu baik, pertahankan ya!');
      });
    },
  );
}
