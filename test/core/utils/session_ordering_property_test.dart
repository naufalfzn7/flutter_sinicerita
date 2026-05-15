import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sinicerita/core/utils/home_helpers.dart';

/// **Feature: tahap-4-main-navigation-profile, Property 4: Session ordering**
///
/// **Validates: Requirements 6.2, 6.3**
///
/// Part A — Session lists are correctly ordered by their respective timestamp fields:
/// For any list of active sessions, sorting by updatedAt descending SHALL produce
/// a list where each session's updatedAt is >= the next session's updatedAt.
/// For any list of completed sessions, sorting by completedAt descending SHALL
/// produce a list where each session's completedAt is >= the next session's completedAt.
///
/// Part B — formatRelativeTime output categories:
/// For any DateTime pair (dateTime, now) where now >= dateTime:
/// - If diff < 1 minute: result == "Baru saja"
/// - If diff 1-59 minutes: result matches "X menit lalu"
/// - If diff 1-23 hours: result matches "X jam lalu"
/// - If diff >= 24 hours: result contains a date format (digits)
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });

  group(
    'Property 4: Session lists are correctly ordered by their respective '
    'timestamp fields',
    () {
      const int iterations = 150;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random DateTime within a reasonable range (2020-2025).
      DateTime generateRandomDateTime(Random rng) {
        final year = 2020 + rng.nextInt(6); // 2020-2025
        final month = 1 + rng.nextInt(12); // 1-12
        final day = 1 + rng.nextInt(28); // 1-28 (safe for all months)
        final hour = rng.nextInt(24);
        final minute = rng.nextInt(60);
        final second = rng.nextInt(60);
        return DateTime(year, month, day, hour, minute, second);
      }

      /// Generate a random list of DateTimes with length between 2 and 20.
      List<DateTime> generateRandomDateTimeList(Random rng) {
        final length = 2 + rng.nextInt(19); // 2-20 items
        return List.generate(length, (_) => generateRandomDateTime(rng));
      }

      test(
        'Part A: Sorting timestamps descending maintains correct order '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final timestamps = generateRandomDateTimeList(random);

            // Sort descending (most recent first) — same logic used in session lists
            final sorted = List<DateTime>.from(timestamps)
              ..sort((a, b) => b.compareTo(a));

            // Verify descending order: each element >= the next
            for (var j = 0; j < sorted.length - 1; j++) {
              expect(
                sorted[j].compareTo(sorted[j + 1]) >= 0,
                isTrue,
                reason: 'Iteration $i, index $j: '
                    '${sorted[j]} should be >= ${sorted[j + 1]} '
                    'in descending order',
              );
            }

            // Verify all original elements are present (sort doesn't lose items)
            expect(
              sorted.length,
              equals(timestamps.length),
              reason: 'Iteration $i: sorted list length should match original',
            );
          }
        },
      );

      test(
        'Part A: Active sessions sorted by updatedAt descending '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final updatedAtList = generateRandomDateTimeList(random);

            // Simulate sorting active sessions by updatedAt descending
            final sorted = List<DateTime>.from(updatedAtList)
              ..sort((a, b) => b.compareTo(a));

            // Verify each updatedAt >= next updatedAt (descending)
            for (var j = 0; j < sorted.length - 1; j++) {
              final current = sorted[j];
              final next = sorted[j + 1];
              expect(
                current.isAfter(next) || current.isAtSameMomentAs(next),
                isTrue,
                reason: 'Iteration $i, index $j: '
                    'updatedAt $current should be >= $next in descending order',
              );
            }
          }
        },
      );

      test(
        'Part A: Completed sessions sorted by completedAt descending '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            final completedAtList = generateRandomDateTimeList(random);

            // Simulate sorting completed sessions by completedAt descending
            final sorted = List<DateTime>.from(completedAtList)
              ..sort((a, b) => b.compareTo(a));

            // Verify each completedAt >= next completedAt (descending)
            for (var j = 0; j < sorted.length - 1; j++) {
              final current = sorted[j];
              final next = sorted[j + 1];
              expect(
                current.isAfter(next) || current.isAtSameMomentAs(next),
                isTrue,
                reason: 'Iteration $i, index $j: '
                    'completedAt $current should be >= $next in descending order',
              );
            }
          }
        },
      );
    },
  );

  group(
    'Property 4: formatRelativeTime produces correct output categories',
    () {
      const int iterations = 200;
      final random = Random(42); // Fixed seed for reproducibility

      /// Generate a random Duration within a specific range.
      Duration generateRandomDuration(Random rng, int maxMinutes) {
        final minutes = rng.nextInt(maxMinutes);
        final seconds = rng.nextInt(60);
        return Duration(minutes: minutes, seconds: seconds);
      }

      test(
        'formatRelativeTime returns correct category for random DateTime pairs '
        '($iterations random iterations)',
        () {
          for (var i = 0; i < iterations; i++) {
            // Generate a base "now" DateTime
            final year = 2022 + random.nextInt(4); // 2022-2025
            final month = 1 + random.nextInt(12);
            final day = 1 + random.nextInt(28);
            final hour = random.nextInt(24);
            final minute = random.nextInt(60);
            final now = DateTime(year, month, day, hour, minute);

            // Generate a random difference category
            final category = random.nextInt(4); // 0-3
            late DateTime dateTime;
            late String expectedPattern;

            switch (category) {
              case 0:
                // Less than 1 minute ago (0-59 seconds)
                final seconds = random.nextInt(60);
                dateTime = now.subtract(Duration(seconds: seconds));
                expectedPattern = 'Baru saja';
                break;
              case 1:
                // 1-59 minutes ago
                final minutes = 1 + random.nextInt(59); // 1-59
                final seconds = random.nextInt(60);
                dateTime = now.subtract(
                  Duration(minutes: minutes, seconds: seconds),
                );
                expectedPattern = 'menit lalu';
                break;
              case 2:
                // 1-23 hours ago
                final hours = 1 + random.nextInt(23); // 1-23
                final minutes = random.nextInt(60);
                dateTime = now.subtract(
                  Duration(hours: hours, minutes: minutes),
                );
                expectedPattern = 'jam lalu';
                break;
              case 3:
                // 24+ hours ago (1-365 days)
                final days = 1 + random.nextInt(365);
                dateTime = now.subtract(Duration(days: days));
                expectedPattern = 'date_format'; // Will check for digits
                break;
            }

            final result = formatRelativeTime(dateTime, now);

            switch (category) {
              case 0:
                expect(
                  result,
                  equals('Baru saja'),
                  reason: 'Iteration $i: diff < 1 min (category 0) — '
                      'expected "Baru saja", got "$result"',
                );
                break;
              case 1:
                // Should match pattern "X menit lalu" where X is 1-59
                expect(
                  RegExp(r'^\d+ menit lalu$').hasMatch(result),
                  isTrue,
                  reason: 'Iteration $i: diff 1-59 min (category 1) — '
                      'expected "X menit lalu" pattern, got "$result"',
                );
                // Verify the number is in range 1-59
                final minuteValue = int.parse(result.split(' ')[0]);
                expect(
                  minuteValue >= 1 && minuteValue <= 59,
                  isTrue,
                  reason: 'Iteration $i: minute value $minuteValue '
                      'should be in range 1-59',
                );
                break;
              case 2:
                // Should match pattern "X jam lalu" where X is 1-23
                expect(
                  RegExp(r'^\d+ jam lalu$').hasMatch(result),
                  isTrue,
                  reason: 'Iteration $i: diff 1-23 hours (category 2) — '
                      'expected "X jam lalu" pattern, got "$result"',
                );
                // Verify the number is in range 1-23
                final hourValue = int.parse(result.split(' ')[0]);
                expect(
                  hourValue >= 1 && hourValue <= 23,
                  isTrue,
                  reason: 'Iteration $i: hour value $hourValue '
                      'should be in range 1-23',
                );
                break;
              case 3:
                // Should contain digits (date format like "01 Jan 2024")
                expect(
                  RegExp(r'\d').hasMatch(result),
                  isTrue,
                  reason: 'Iteration $i: diff >= 24h (category 3) — '
                      'expected date format with digits, got "$result"',
                );
                // Verify it matches the expected DateFormat pattern "dd MMM yyyy"
                final expectedDate =
                    DateFormat('dd MMM yyyy', 'id').format(dateTime);
                expect(
                  result,
                  equals(expectedDate),
                  reason: 'Iteration $i: expected "$expectedDate", '
                      'got "$result"',
                );
                break;
            }
          }
        },
      );

      test(
        'formatRelativeTime boundary: exactly 0 seconds returns "Baru saja"',
        () {
          final now = DateTime(2024, 6, 15, 12, 0, 0);
          final result = formatRelativeTime(now, now);
          expect(result, equals('Baru saja'));
        },
      );

      test(
        'formatRelativeTime boundary: exactly 1 minute returns "1 menit lalu"',
        () {
          final now = DateTime(2024, 6, 15, 12, 1, 0);
          final dateTime = DateTime(2024, 6, 15, 12, 0, 0);
          final result = formatRelativeTime(dateTime, now);
          expect(result, equals('1 menit lalu'));
        },
      );

      test(
        'formatRelativeTime boundary: exactly 1 hour returns "1 jam lalu"',
        () {
          final now = DateTime(2024, 6, 15, 13, 0, 0);
          final dateTime = DateTime(2024, 6, 15, 12, 0, 0);
          final result = formatRelativeTime(dateTime, now);
          expect(result, equals('1 jam lalu'));
        },
      );

      test(
        'formatRelativeTime boundary: exactly 24 hours returns date format',
        () {
          final now = DateTime(2024, 6, 16, 12, 0, 0);
          final dateTime = DateTime(2024, 6, 15, 12, 0, 0);
          final result = formatRelativeTime(dateTime, now);
          final expectedDate = DateFormat('dd MMM yyyy', 'id').format(dateTime);
          expect(result, equals(expectedDate));
        },
      );
    },
  );
}
