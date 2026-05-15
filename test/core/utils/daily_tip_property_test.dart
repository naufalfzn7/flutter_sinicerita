import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinicerita/core/utils/home_helpers.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 3: Daily tip index**
///
/// **Validates: Requirements 5.4**
///
/// For any date and any tips array length > 0, the getDailyTipIndex function
/// SHALL:
/// - Return the same index for the same date (deterministic)
/// - Return an index in the range [0, tipsCount)
/// - Return a different index for consecutive days (when tipsCount > 1)
void main() {
  group(
    'Property 3: Daily tip index is deterministic and bounded',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random DateTime between 2020-01-01 and 2030-12-31.
      DateTime generateRandomDate(Random rng) {
        final year = 2020 + rng.nextInt(11); // 2020-2030
        final month = 1 + rng.nextInt(12); // 1-12
        final maxDay = DateTime(year, month + 1, 0).day; // days in month
        final day = 1 + rng.nextInt(maxDay); // 1-maxDay
        return DateTime(year, month, day);
      }

      test(
        'determinism: same date and tipsCount always returns same index '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final date = generateRandomDate(random);
            final tipsCount = 1 + random.nextInt(30); // 1-30

            final result1 = getDailyTipIndex(date, tipsCount);
            final result2 = getDailyTipIndex(date, tipsCount);

            expect(
              result1,
              equals(result2),
              reason: 'Iteration $i: date=$date, tipsCount=$tipsCount — '
                  'calling twice should return same index, '
                  'got $result1 and $result2',
            );
          }
        },
      );

      test(
        'bounds: result is always >= 0 and < tipsCount '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final date = generateRandomDate(random);
            final tipsCount = 1 + random.nextInt(30); // 1-30

            final result = getDailyTipIndex(date, tipsCount);

            expect(
              result,
              greaterThanOrEqualTo(0),
              reason: 'Iteration $i: date=$date, tipsCount=$tipsCount — '
                  'result should be >= 0, got $result',
            );
            expect(
              result,
              lessThan(tipsCount),
              reason: 'Iteration $i: date=$date, tipsCount=$tipsCount — '
                  'result should be < $tipsCount, got $result',
            );
          }
        },
      );

      test(
        'different index for consecutive days when tipsCount > 1 '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final date = generateRandomDate(random);
            final tipsCount = 2 + random.nextInt(29); // 2-30 (must be > 1)
            final nextDay = date.add(const Duration(days: 1));

            final indexToday = getDailyTipIndex(date, tipsCount);
            final indexTomorrow = getDailyTipIndex(nextDay, tipsCount);

            expect(
              indexToday,
              isNot(equals(indexTomorrow)),
              reason: 'Iteration $i: date=$date, nextDay=$nextDay, '
                  'tipsCount=$tipsCount — consecutive days should have '
                  'different indices, both got $indexToday',
            );
          }
        },
      );
    },
  );
}
